from flytekit import task, workflow


# Define a task that produces the string "Hello, World!"
# by using the `@task` decorator to annotate the Python function
@task
def say_hello(planet:str="Mars") -> str:
    return f"Hello, {planet}!\n"

@task
def times_what(phrase:str, n:int) -> str:
    return phrase*n

# Handle the output of a task like that of a regular Python function.
@workflow
def hello_world_wf(planet:str="World", n:int=2) -> str:
    res1 = say_hello(planet)
    res = times_what(res1,n)
    return res


# Run the workflow locally by calling it like a Python function
if __name__ == "__main__":
    print(f"Running hello_world_wf() {hello_world_wf()}")
