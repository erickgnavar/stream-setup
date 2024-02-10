import asyncio
import json
import logging
import sys
from array import array
from uuid import uuid4

import usb.core
import usb.util
import websockets

# configure websocket logger
ws_logger = logging.getLogger("websockets")
ws_logger.setLevel(logging.DEBUG)
ws_logger.addHandler(logging.StreamHandler())

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


async def send_message(type, data):
    """
    Open a connection and send a message
    """
    message_id = uuid4().hex
    # all request(when we ask for some action) messages need to have op 6
    payload = {
        "op": 6,
        "d": {"requestId": message_id, "requestType": type, "requestData": data},
    }

    # TODO: reuse connection to avoid open a new one on every message
    async with websockets.connect("ws://localhost:4455") as websocket:
        # wait for hello message, it should be a op code 0
        _message = await websocket.recv()

        response = {"op": 1, "d": {"rpcVersion": 1}}
        # send op code 1 message to confirm we have a identified connection
        await websocket.send(json.dumps(response))

        # send actual message
        await websocket.send(json.dumps(payload))

        return message_id


async def change_scene(scene_name):
    await send_message("SetCurrentProgramScene", {"sceneName": scene_name})


async def toggle_microphone(mute: bool):
    # "Mic" name is defined in obs
    await send_message("SetInputMute", {"inputName": "Mic", "inputMuted": not mute})


# these are the identifiers for numeric keyboard
# TODO: make this configurable
device = usb.core.find(idVendor=0x8089, idProduct=0x0004)

logger.info(f"Connection to device {device}")


if not device:
    logger.error("USB device not found")
    sys.exit(0)

interface = device[0].interfaces()[0].bInterfaceNumber

endpoint = device[0].interfaces()[0].endpoints()[0]

keypad = {
    # first row
    "1": array("B", [0, 0, 17, 0, 0, 0, 0, 0]),
    "2": array("B", [0, 0, 16, 0, 0, 0, 0, 0]),
    "3": array("B", [0, 0, 15, 0, 0, 0, 0, 0]),
    "4": array("B", [0, 0, 14, 0, 0, 0, 0, 0]),
    # second row
    "5": array("B", [0, 0, 10, 0, 0, 0, 0, 0]),
    "6": array("B", [0, 0, 11, 0, 0, 0, 0, 0]),
    "7": array("B", [0, 0, 12, 0, 0, 0, 0, 0]),
    "8": array("B", [0, 0, 13, 0, 0, 0, 0, 0]),
    # third row
    "9": array("B", [0, 0, 9, 0, 0, 0, 0, 0]),
    "10": array("B", [0, 0, 8, 0, 0, 0, 0, 0]),
    "11": array("B", [0, 0, 7, 0, 0, 0, 0, 0]),
    "12": array("B", [0, 0, 6, 0, 0, 0, 0, 0]),
    # sixth row
    "end": array("B", [0, 0, 33, 0, 0, 0, 0, 0]),
}


try:
    if device.is_kernel_driver_active(interface):
        # tell kernel to stop listening this deviceice
        # so we can listen it exclusively
        device.detach_kernel_driver(interface)

    address = endpoint.bEndpointAddress

    logger.info("Ready to listen keyboard...")

    # by default endpoint.wMaxPacketSize is 8
    while buffer := device.read(address, endpoint.wMaxPacketSize, 10000000):
        if buffer == keypad["1"]:
            asyncio.run(change_scene("master"))
            asyncio.run(toggle_microphone(True))

        elif buffer == keypad["2"]:
            asyncio.run(change_scene("secret"))
            asyncio.run(toggle_microphone(True))

        elif buffer == keypad["3"]:
            asyncio.run(change_scene("brb"))
            asyncio.run(toggle_microphone(False))

        elif buffer == keypad["4"]:
            asyncio.run(change_scene("whiteboard"))
            asyncio.run(toggle_microphone(True))

        elif buffer == keypad["5"]:
            asyncio.run(change_scene("standby"))
            asyncio.run(toggle_microphone(False))

        elif buffer == keypad["7"]:
            asyncio.run(change_scene("intro"))
            asyncio.run(toggle_microphone(False))

        elif buffer == keypad["8"]:
            asyncio.run(change_scene("outro"))
            asyncio.run(toggle_microphone(False))

        elif buffer == keypad["end"]:
            # we need to exit program this way because it's only listening to
            # numeric keyboard and we can't press ctrl-c there
            logger.info("Exiting program")
            sys.exit(0)

except Exception as ex:
    logger.error("there was an error: %s", str(ex))
    # TODO: find a way to return control to kernel
