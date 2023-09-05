from shutil import which
import argparse
from loader import Simulation, compile
import pickle
from ml import RLCTransformer
import torch


def load_network(path, ntokens, device):
    if path == "":
        return RLCTransformer(ntokens=ntokens, device=device)
    return torch.load(path)


def load_dataset(path):
    to_return = []
    with open(path, "rb") as f:
        while True:
            try:
                loaded = pickle.load(f)
                for (state, actions_and_scores) in loaded:
                    to_return.append((state, actions_and_scores))
            except Exception as e:
                break
    return to_return


def make_rlc_argparse(name, description):
    parser = argparse.ArgumentParser(name, description=description)
    parser.add_argument(
        "--wrapper",
        "-w",
        type=str,
        nargs="?",
        help="path to wrapper to load",
        default="wrapper.py",
    )
    parser.add_argument(
        "--include",
        "-i",
        type=str,
        nargs="*",
        help="path to folder where rl files can be found",
        default=[],
    )
    parser.add_argument(
        "--rlc",
        "-c",
        type=str,
        nargs="?",
        help="path to rlc compiler",
        default="rlc",
    )
    parser.add_argument(
        "--source",
        "-rl",
        type=str,
        nargs="?",
        help="path to .rl source file",
    )
    return parser


def load_simulation_from_args(args):
    assert (
        which(args.rlc) is not None
    ), "could not find executable {}, use --rlc <path_to_rlc> to configure it".format(
        args.rlc
    )

    sim = (
        Simulation(args.wrapper[0])
        if len(args.wrapper) == 1
        else compile(args.source, args.rlc, args.include)
    )
    return sim