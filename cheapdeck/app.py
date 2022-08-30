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


async def send_message(message):
    """
    Open a connection and send a message
    """
    message_id = uuid4().hex
    message["message-id"] = message_id

    # TODO: reuse connection to avoid open a new one on every message
    async with websockets.connect("ws://localhost:4444") as websocket:
        await websocket.send(json.dumps(message))

        return message_id


async def change_scene(scene_name):
    await send_message(
        {
            "request-type": "SetCurrentScene",
            "scene-name": scene_name,
        }
    )


async def toggle_microphone(mute: bool):
    # "Mic" name is defined in obs
    await send_message(
        {
            "request-type": "SetMute",
            "source": "Mic",
            "mute": not mute,
        }
    )


# these are the identifiers for numeric keyboard
# TODO: make this configurable
device = usb.core.find(idVendor=0x13BA, idProduct=0x0001)


if not device:
    logger.error("USB device not found")
    sys.exit(0)

interface = device[0].interfaces()[0].bInterfaceNumber

device.reset()

endpoint = device[0].interfaces()[0].endpoints()[0]

keypad = {
    "0": array("B", [0, 0, 83, 0, 0, 0, 0, 0]),
    "/": array("B", [0, 0, 84, 0, 0, 0, 0, 0]),
    "*": array("B", [0, 0, 85, 0, 0, 0, 0, 0]),
    "+": array("B", [0, 0, 86, 0, 0, 0, 0, 0]),
    "-": array("B", [0, 0, 87, 0, 0, 0, 0, 0]),
    "enter": array("B", [0, 0, 88, 0, 0, 0, 0, 0]),
    "1": array("B", [0, 0, 89, 0, 0, 0, 0, 0]),
    "2": array("B", [0, 0, 90, 0, 0, 0, 0, 0]),
    "3": array("B", [0, 0, 91, 0, 0, 0, 0, 0]),
    "4": array("B", [0, 0, 92, 0, 0, 0, 0, 0]),
    "5": array("B", [0, 0, 93, 0, 0, 0, 0, 0]),
    "6": array("B", [0, 0, 94, 0, 0, 0, 0, 0]),
    "7": array("B", [0, 0, 95, 0, 0, 0, 0, 0]),
    "8": array("B", [0, 0, 96, 0, 0, 0, 0, 0]),
    "9": array("B", [0, 0, 97, 0, 0, 0, 0, 0]),
    ".": array("B", [0, 0, 99, 0, 0, 0, 0, 0]),
    "backspace": array("B", [0, 0, 42, 0, 0, 0, 0, 0]),
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

        elif buffer == keypad["enter"]:
            # we need to exit program this way because it's only listening to
            # numeric keyboard and we can't press ctrl-c there
            logger.info("Exiting program")
            sys.exit(0)

except Exception as ex:
    logger.error("there was an error: %s", str(ex))
    # TODO: find a way to return control to kernel
