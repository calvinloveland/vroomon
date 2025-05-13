import random
from vroomon.car.powertrain import PowertrainPart

class Cylinder(PowertrainPart):
    def __init__(self,power):
        self.power = power

    @classmethod
    def from_random(cls,power_mu=100,power_sigma=.25):
        return cls(random.normalvariate(power_mu, power_sigma))