import asyncio
from typing import List

import flyte

env = flyte.TaskEnvironment(
    name="hello_v2",
)


@env.task()
async def hello_worker(id: int) -> str:
    return f"hello, my id is: {id} and I am being run by Action: {flyte.ctx().action}"


@env.task()
async def hello_driver(ids: List[int] = [1, 2, 3]) -> List[str]:
    coros = []
    with flyte.group("fanout-group"):
        for id in ids:
            coros.append(hello_worker(id))

        vals = await asyncio.gather(*coros)

    return vals


if __name__ == "__main__":
    # flyte.init_from_config("../../config.yaml")
    flyte.init()

    run = flyte.run(hello_driver)
    print(run.name)
    print(run.url)
    print(run.outputs())
    run.wait(run)