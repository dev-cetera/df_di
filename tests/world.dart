//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: omit_local_variable_types, invalid_use_of_visible_for_testing_member

import 'package:df_di/df_di.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  // Create a new world for players or users to exist in.
  final world = World();

  // Create a new player in the world.
  final player1 = world.createUniqueEntity();

  // Spawn the player in the world with the components Name, Position and Velocity.
  world.addAllComponents(player1, {
    const Name('Player 1'),
    const Position(x: 0, y: 0),
    const Velocity(x: 1, y: 0),
  });

  // Print the current position.
  final p0 = player1.getComponent<Position>();
  print('Position 0: (${p0.x}, ${p0.y})');

  // Update the movement in the world.
  final movementSystem = MovementSystem();
  movementSystem.update(world);

  // Print the position after the world update.
  final p1 = player1.getComponent<Position>();
  print('Position 1: (${p1.x}, ${p1.y})');

  // Print the player name.
  final name = player1.getComponent<Name>().name;
  print('Player name: "$name"');
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract class UpdateSystem {
  void update(World entityManger);
}

class MovementSystem extends UpdateSystem {
  @override
  void update(World entityManger) {
    // Get all entities with both Position and Velocity components.
    final entities = entityManger.query2<Position, Velocity>();
    for (var entity in entities) {
      // Update the position based on the velocity
      final Position position = entity.getComponent();
      final Velocity velocity = entity.getComponent();
      final result = entityManger.updateComponent(
        entity,
        position.add(velocity),
      );
      final newPosition = result.unwrap() as Position;

      // Log the updated position.
      print('Updated Position: (${newPosition.x}, ${newPosition.y})');
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class Name extends Component {
  final String name;
  const Name(this.name);

  @override
  List<Object?> get props => [name];
}

class Vector extends Component {
  final double x;
  final double y;
  const Vector({this.x = 0.0, this.y = 0.0});

  Vector add(Vector other) {
    return Vector(x: x + other.x, y: y + other.y);
  }

  @override
  List<Object?> get props => [x, y];
}

class Position extends Vector {
  const Position({super.x = 0.0, super.y = 0.0});

  @override
  Position add(Vector other) {
    return Position(x: x + other.x, y: y + other.y);
  }
}

class Velocity extends Vector {
  const Velocity({super.x = 0.0, super.y = 0.0});

  @override
  Velocity add(Vector other) {
    return Velocity(x: x + other.x, y: y + other.y);
  }
}
