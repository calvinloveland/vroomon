class PowertrainPart:
    def to_dna(self):
        raise NotImplementedError

    @classmethod
    def from_dna(cls, dna):
        raise NotImplementedError
