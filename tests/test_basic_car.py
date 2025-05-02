from vroomon.car import Car
from vroomon.ground import Ground
from vroomon.simulation import Simulation

CAR_DNA = {
    "frame": ["C", "G", "D", "D", "G"],  # C = Chassis, G = Gear, D = DriveShaft
    "powertrain": ["R", "W", "R", "R", "W"],  # R = Rectangle, W = Wheel
}


def test_car():
    car = Car(CAR_DNA)
    ground = Ground()
    simulation = Simulation()
    score = simulation.score_car(car, ground)
    assert score > 0, "Car should have a positive score on the ground"
