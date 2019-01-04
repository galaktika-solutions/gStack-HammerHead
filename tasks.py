from invoke import task


@task(help={'name': 'The name of the program'})
def build(c, name):
    """
    Build a program.
    """
    print("Building {}!".format(name))
