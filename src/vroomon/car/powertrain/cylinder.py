import random
from vroomon.car.powertrain import PowertrainPart


class Cylinder(PowertrainPart):
    def __init__(self, power):
        self.power = power

    @classmethod
    def from_random(cls, power_mu=100, power_sigma=0.25):
        return cls(random.normalvariate(power_mu, power_sigma))

    def to_dna(self):
        return {"type": "C", "power": self.power}

    @classmethod
    def from_dna(cls, dna):
        return cls(dna["power"])
