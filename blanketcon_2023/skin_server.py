
import io
from uuid import UUID
import logging

import aiohttp
import aiohttp.web_exceptions
from aiohttp import web
from PIL import Image

from .skin_convert import convert_skin

routes = web.RouteTableDef()


@routes.get("/{uuid:[0-9a-f]{32}}")
async def hello(request: web.Request):
    client: aiohttp.ClientSession = request.app["client"]

    uuid = UUID(request.match_info["uuid"]).hex

    async with client.get(f"https://crafthead.net/body/{uuid}/32") as req:
        texture_contents = await req.read()

    texture = Image.open(io.BytesIO(texture_contents))
    return web.Response(text=convert_skin(texture))


async def with_session(app: web.Application):
    async with aiohttp.ClientSession() as session:
        app["client"] = session
        yield


def main() -> None:
    logging.basicConfig(level=logging.DEBUG)

    app = web.Application()
    app.cleanup_ctx.append(with_session)
    app.add_routes(routes)
    web.run_app(app, host="127.0.0.1", port=8765)


if __name__ == "__main__":
    main()
