import random
from vroomon.car.powertrain import PowertrainPart


class DriveShaft(PowertrainPart):
    def __init__(self, efficiency):
        self.efficiency = efficiency

    @classmethod
    def from_random(cls, efficiency_mu=0.9, efficiency_sigma=0.1):
        return cls(random.normalvariate(efficiency_mu, efficiency_sigma))

    def to_dna(self):
        return {"type": "D", "efficiency": self.efficiency}

    @classmethod
    def from_dna(cls, dna):
        return cls(dna["efficiency"])
