from vroomon.car import Car
from vroomon.ground import Ground
from vroomon.simulation import Simulation

CAR_DNA = {
    "powertrain": ["C", "G", "D", "D", "G"],  # C = Cylinder, G = Gear, D = DriveShaft
    "frame": ["R", "W", "R", "R", "W"],  # R = Rectangle, W = Wheel
}


def test_car():
    car = Car(CAR_DNA)
    ground = Ground()
    simulation = Simulation()
    score = simulation.score_car(car, ground)
    assert score > 0, "Car should have a positive score on the ground"


def test_car_with_empty_dna():
    empty_dna = {"frame": [], "powertrain": []}
    try:
        car = Car(empty_dna)
        assert False, "Car should not be created with empty DNA"
    except ValueError as e:
        pass


def test_simulation_with_high_gravity():
    car = Car(CAR_DNA)
    ground = Ground()
    simulation = Simulation()
    simulation.space.gravity = (0, 100)  # Extreme gravity
    score = simulation.score_car(car, ground)
    assert score > 0, "Car should still have a positive score under high gravity"
