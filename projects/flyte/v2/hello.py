# hello.py
# /// script
# requires-python = ">=3.10"
# dependencies = ["flyte>=2.0.0b0"]
# ///

import flyte
import asyncio 

env = flyte.TaskEnvironment(
    name="hello_world",
    resources=flyte.Resources(memory="250Mi")
)

@env.task
def calculate(x: int) -> int:
    return x * 2 + 5

@env.task
async def main(numbers: list[int]) -> float:
    # Parallel execution across distributed containers
    results = await asyncio.gather(*[
        calculate.aio(num) for num in numbers
    ])
    return sum(results) / len(results)

if __name__ == "__main__":
    flyte.init()
    # flyte.init_from_config("config.yaml")
    run = flyte.run(main, numbers=list(range(10)))
    # print(f"Result: {run.result}")
    # print(f"View at: {run.url}")
    print(run.outputs())