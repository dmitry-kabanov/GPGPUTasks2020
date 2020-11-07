import os
import sys
import json
import shutil
import platform
import traceback
import subprocess
from pathlib import Path

import git
import requests

github_api_token = ""

if platform.system() == "Windows":
    cmake_exe = "C:/Program Files/JetBrains/CLion 2020.1/bin/cmake/win/bin/cmake.exe"
    cmake_init_params = ["-G", "Visual Studio 16 2019", "-A", "x64", ".."]
    build_exe = cmake_exe
    build_params = ["-j", "8", "--config", "Release"]
    exec_path_template = "build/Release/{}.exe"
    exec_device_index = ["0"]
elif platform.system() == "Linux":
    cmake_exe = "/usr/bin/cmake"
    cmake_init_params = ["-DCMAKE_BUILD_TYPE=RelWithDebInfo", ".."]
    build_exe = "make"
    build_params = ["-j8"]
    exec_path_template = "build/{}"
    exec_device_index = ["1"]
else:
    raise "Unsupported platform: {}".format(platform.system())


def load_json(url):
    data = requests.get(url, auth=('user', github_api_token)).text
    return json.loads(data)


def execute(exec, *args, decode=False, output_path=None):
    exe_exception = None

    try:
        exec_output = subprocess.check_output([exec, *args])
    except subprocess.CalledProcessError as e:
        exec_output = e.output
        exe_exception = e

    if decode:
        exec_output = exec_output.decode('utf-8')

    if output_path is not None:
        with open(output_path, "wb") as output:
            output.write(exec_output)

    if exe_exception is not None:
        raise exe_exception

    return exec_output


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: {} <rootDir>".format(sys.argv[0]))
        sys.exit(1)

    root_dir = Path(sys.argv[1])
    print("Root dir: {}".format(root_dir))

    repository_name = "GPGPUCourse/GPGPUTasks2020"

    task_to_exec = {
        "task01": ["aplusb"],
        "task03": ["mandelbrot", "sum", "max_prefix_sum"],
        "task04": ["matrix_transpose", "matrix_multiplication"],
        "task05": ["bitonic", "radix"],
        "task06": ["merge"],
    }

    pr_ignore_list_filename = root_dir / "input/pr_ignore_list.txt"
    repos_dir = str(root_dir / "repos/{task}/{username}/")
    output_path = str(Path(repos_dir) / "{output}.txt")

    cmake_version_output = execute(cmake_exe, "--version", decode=True)
    print(cmake_version_output)

    with open(pr_ignore_list_filename) as input:
        ignored_prs = input.readlines()
        if len(ignored_prs) > 0:
            print("{} ignored PRs: [{}]".format(len(ignored_prs), ", ".join(ignored_prs)))
        ignored_prs = list(map(int, ignored_prs))

    data = load_json("https://api.github.com/repos/{}/pulls?state=open".format(repository_name))
    print("{} Pull Requests...".format(len(data)))
    for pr in sorted(data, key=lambda x: x['number']):
        try:
            number = pr['number']
            url = pr['html_url']
            print("PR#{}".format(number))
            if number in ignored_prs:
                print("  ignored!")
                continue
            pr_data = load_json(pr['url'])
            title = pr_data['title']
            print("  {}".format(url))
            print("  {}".format(title))
            username = pr_data['user']['login']
            # print("  User: {}".format(username))
            head_repo = pr_data['head']['repo']['full_name']
            head_branch = pr_data['head']['ref']
            base_branch = pr_data['base']['ref']
            if head_branch != base_branch:
                print("  Fail! Branch mismatch!")
                continue
            task = head_branch
            print("  Repo: {}:{}".format(head_repo, head_branch))
            if task not in task_to_exec:
                print("    NOTHING TO EXECUTE!")
                continue
            user_task_dir = Path(repos_dir.format(username=username, task=task))
            user_task_dir.mkdir(parents=True, exist_ok=True)
            print("  Working dir: {}".format(user_task_dir))
            repo_git_url = pr_data['head']['repo']['git_url']
            repo_dir = user_task_dir / pr_data['head']['repo']['name']
            if not repo_dir.exists():
                repo = git.Repo.clone_from(repo_git_url, repo_dir, branch=task)
                repo.git.pull()
                print("    cloned!")
            else:
                repo = git.Repo(repo_dir)
                print("    already cloned!")
            build_dir = repo_dir / 'build'
            if build_dir.exists():
                print("    already build!")
                continue

                print("    cleaning build...")
                for x in build_dir.glob("*"):
                    if x.is_file():
                        x.unlink()
                    else:
                        shutil.rmtree(x)
            else:
                build_dir.mkdir(exist_ok=False)
            print("    building...")
            os.chdir(build_dir)
            print("      cmake init...")
            cmake_init_output_path = output_path.format(task=task, username=username, output="cmake_init")
            cmake_init_output = execute(cmake_exe, *cmake_init_params, output_path=cmake_init_output_path)
            print("      cmake build...")
            cmake_build_output_path = output_path.format(task=task, username=username, output="cmake_build")
            cmake_build_output = execute(build_exe, *((["--build", str(build_dir)] if platform.system() == "Windows" else []) + build_params),
                                         output_path=cmake_build_output_path)
            print("  executing...")
            for exec_name in task_to_exec[task]:
                os.chdir(repo_dir)
                print("    ./{}.exe...".format(exec_name))
                exec_output_path = output_path.format(task=task, username=username, output="exe_{}".format(exec_name))
                execute(exec_path_template.format(exec_name), *exec_device_index, output_path=exec_output_path)
        except Exception as e:
            print(traceback.format_exc())
