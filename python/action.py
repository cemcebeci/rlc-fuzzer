#
# This file is part of the RLC project.
#
# RLC is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 2 as published by the Free Software Foundation.
#
# RLC is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with RLC. If not, see <https://www.gnu.org/licenses/>.
#
import argparse
from loader.simulation import dump
from loader import Simulation, compile, State
from solvers import find_end
from shutil import which
from command_line import load_simulation_from_args, make_rlc_argparse, load_network


def main():
    parser = make_rlc_argparse("solve", description="runs a action of the simulation")
    parser.add_argument(
        "--load",
        "-l",
        type=str,
        nargs="?",
        help="path where to write the output",
        default="",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        nargs="?",
        help="path where to write the output",
        default="",
    )
    parser.add_argument(
        "actions",
        type=str,
        nargs="+",
        help="actions",
        default=[],
    )
    parser.add_argument("--show-actions", "-a", action="store_true", default=False)

    args = parser.parse_args()
    sim = load_simulation_from_args(args)

    if args.show_actions:
        sim.dump()
        return

    state = sim.start(["play"])
    if args.load != "":
        state.load(args.load)

    if not state.is_done():
        print(*args.actions)
        state.execute(*args.actions)

    if args.output != "":
        state.write(args.output)
    else:
        state.dump()


if __name__ == "__main__":
    main()
