import copy
import random

from vroomon.car.frame import rectangle
from vroomon.car.frame import wheel
from vroomon.car.powertrain.cylinder import Cylinder
from vroomon.car.powertrain.driveshaft import DriveShaft
from vroomon.car.powertrain.gearset import GearSet


ALL_FRAME_PARTS = [

SEQUENCE_LENGTH = 3

def mutate(car):


def reproduce(car1, car2):
    mother_car = random.choice([car1, car2])
    other_car = car1 if mother_car == car2 else car2
    car3 = copy.deepcopy(mother_car)
    for i in len(car3.frame):
        if random.random() < 0.5:
            for j in range(SEQUENCE_LENGTH):
                if i + j < len(car3.frame):
                    car3.frame[i + j] = other_car.frame[i + j]
        if random.random() < 0.5:
            for j in range(SEQUENCE_LENGTH):
                if i + j < len(car3.powertrain):
                    car3.powertrain[i + j] = other_car.powertrain[i + j]
    


