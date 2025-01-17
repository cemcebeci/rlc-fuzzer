# RUN: python %pyscript/test.py --source %s -i %stdlib --rlc rlc

import collections.vector
import serialization.to_byte_vector
import direction
import math.numeric
import unit 
import board 
import move

fun manhattan_distance(Int x1, Int x2, Int y1, Int y2) -> Int:
  let x = x1 - x2
  let y = y1 - y2 
  if x < 0:
    x = -x
  if y < 0:
    y = -y
  return x + y

fun score(Game state) -> Int:
  let x = state.board.units.get(0).x
  let y = state.board.units.get(0).y
  return 100 - manhattan_distance(x, 22, y, 5)

act do_assault(ctx Board board, frm Int unit_id) -> Assault:
  ref source = board.units.get(unit_id)
  frm maybe_dead_unit : Int | Nothing
  maybe_dead_unit = none()
  source.is_overwatching = false
  source.is_guarding = false

  source.action_points = source.action_points - 1

  let target_x = source.x + source.direction.to_x()
  let target_y = source.y + source.direction.to_y()

  let maybe_index = board.get_index_of_unit_at(target_x, target_y)
  if maybe_index is Int:
    frm index = maybe_index
    frm attacker_direction = board.units.get(index).direction
    ref target = board.units.get(maybe_index)

    frm source_roll = source.roll_melee()
    frm target_roll = target.roll_melee()

    if target.is_guarding:
      act guard_reroll(Bool do_it)
      if do_it:
        target_roll = max(target_roll, roll())

      # if defender has not lost, allow to turn
      if source_roll <= target_roll and !attacker_direction.is_facing(board.units.get(index).direction):
        act face_attacker(Bool do_it)
        if do_it:
          board.units.get(index).direction = attacker_direction.opposite()

      # defender won
      if source_roll < target_roll:
        maybe_dead_unit = unit_id

      # attacker won
      if source_roll > target_roll:
        maybe_dead_unit = index

act action_phase(ctx Board board, Faction current_faction) -> ActionPhase:
  while true:
    actions:
      act begin_move(Int unit_id) {
        board.unit_id_is_valid(unit_id)
      }
        subaction*(board) movement = move_unit(board, unit_id)

      act turn(Int unit_id, Int absolute_direction){
        board.unit_id_is_valid(unit_id),
        absolute_direction_is_valid(absolute_direction),
        board.units.get(unit_id).can_turn_to(absolute_direction, false)
      }
        board.units.get(unit_id).turn_direction(absolute_direction, false)

      act shoot(Int unit_id, Int target_id) {
        board.unit_id_is_valid(unit_id),
        board.unit_id_is_valid(target_id),
        board.can_shoot(board.units.get(unit_id), board.units.get(target_id), false)
      }
        if board.shoot_at(board.units.get(unit_id), board.units.get(target_id), false):
          board.units.erase(target_id)

      act overwatch(Int unit_id) {
        board.unit_id_is_valid(unit_id),
        board.units.get(unit_id).can_overwatch()
      }
        board.units.get(unit_id).is_overwatching = true
        board.units.get(unit_id).is_guarding = false

      act guard(Int unit_id) {
        board.unit_id_is_valid(unit_id),
        board.units.get(unit_id).can_guard()
      }
        board.units.get(unit_id).is_guarding = true
        board.units.get(unit_id).is_overwatching = false

      act assault(Int unit_id) {
        board.unit_id_is_valid(unit_id),
        board.can_assault(board.units.get(unit_id))
      }
        subaction*(board) assault_frame = do_assault(board, unit_id)
        let to_kill = assault_frame.maybe_dead_unit
        if to_kill is Int:
          board.units.erase(to_kill)

      act pass_turn()
        return
      
      act quit()
        board.is_done = true
        return

act play() -> Game:
    frm board = make_board()

    while !(board.is_done):
        board.new_turn()
        subaction*(board) marine_frame = action_phase(board, Faction::marine)
        subaction*(board) genestealer_frame = action_phase(board, Faction::genestealer)

fun gen_printer_parser():
  let state = play()
  let serialized = as_byte_vector(state)
  from_byte_vector(state, serialized)

fun main() -> Int:
  let state = play()
  state.quit()
  return int(state.is_done()) - 1

fun test_game_marine_can_step_forward() -> Bool:
  let game = play()
  game.begin_move(0)
  game.move(1)
  game.end_move()
  return game.board.units.get(0).x == 3

fun test_game_marine_can_end_turn() -> Bool:
    let game = play()
    if game.board.units.get(0).action_points != 4:
        return false
    game.begin_move(0)
    game.move(1)
    game.end_move()

    if game.board.units.get(0).action_points != 3:
        return false

    game.pass_turn()
    game.pass_turn()
    return game.board.units.get(0).action_points == 4

fun test_max() -> Bool:
  let x = max(3, 4)
  return x == 4
