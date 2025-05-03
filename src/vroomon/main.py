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
    score = simulation.score_car(car=car, ground=ground, visualize=True)
    assert score > 0, "Car should have a positive score on the ground"


def main():
    test_car()


if __name__ == "__main__":
    main()
