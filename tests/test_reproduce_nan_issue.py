"""Unit test to track down the Car.reproduce issue causing NaN values and IndexErrors."""

import unittest
import random
import copy
from vroomon.car.car import Car


class TestReproduceNaNIssue(unittest.TestCase):
    """Test suite specifically targeting the Car.reproduce bug."""

    def test_reproduce_logic_flaw_demonstration(self):
        """Demonstrate the exact flaw in the reproduce method logic."""
        # Create cars with different lengths - this triggers the bug
        short_car_dna = {
            "frame": ["R", "W"], 
            "powertrain": ["C", "D"]
        }
        short_car = Car(short_car_dna)
        
        long_car_dna = {
            "frame": ["R", "W", "R", "R", "W"], 
            "powertrain": ["C", "D", "G", "D", "C"]
        }
        long_car = Car(long_car_dna)
        
        print("=== Reproduce Logic Flaw Analysis ===")
        print(f"Short car: frame={len(short_car.frame)}, powertrain={len(short_car.powertrain)}")
        print(f"Long car: frame={len(long_car.frame)}, powertrain={len(long_car.powertrain)}")
        
        # The problem is in this part of the reproduce method:
        # The code checks: idx + j < len(child.frame) and idx + j < len(other.frame)
        # But then does: child.frame[idx + j] = other.frame[idx + j]
        # However, it's accessing self.frame and self.powertrain directly which are
        # physics objects, not DNA lists!
        
        print("\nThe bug occurs because:")
        print("1. child.frame contains physics objects (body, shape) tuples")
        print("2. other.frame contains physics objects (body, shape) tuples") 
        print("3. The code tries to assign: child.frame[idx] = other.frame[idx]")
        print("4. This assigns physics objects, which can create NaN values")
        print("5. Plus IndexError when lengths differ")
        
        # Demonstrate the actual problem
        mother = random.choice([short_car, long_car])
        other = short_car if mother == long_car else long_car
        child = copy.deepcopy(mother)
        
        print(f"\nMother selected: {'short' if mother == short_car else 'long'} car")
        print(f"Other car: {'short' if other == short_car else 'long'} car")
        print(f"Child length: {len(child.frame)}")
        print(f"Other length: {len(other.frame)}")
        
        # Show what child.frame actually contains
        print(f"\nchild.frame[0] = {child.frame[0]}")
        print(f"other.frame[0] = {other.frame[0]}")
        print("These are (body, shape) tuples with physics objects!")
        
        # This would cause the NaN issue if executed:
        # child.frame[0] = other.frame[0]  # Assigns physics objects directly!

    def test_reproduce_should_work_on_dna_not_physics(self):
        """Show that reproduce should work on DNA, not physics objects."""
        short_car_dna = {
            "frame": ["R", "W"], 
            "powertrain": ["C", "D"]
        }
        short_car = Car(short_car_dna)
        
        long_car_dna = {
            "frame": ["R", "W", "R", "R", "W"], 
            "powertrain": ["C", "D", "G", "D", "C"]
        }
        long_car = Car(long_car_dna)
        
        print("=== Correct DNA-based reproduction ===")
        
        # Get the DNA from both cars
        short_dna = short_car.to_dna()
        long_dna = long_car.to_dna()
        
        print(f"Short car DNA: {short_dna}")
        print(f"Long car DNA: {long_dna}")
        
        # This is what the reproduce method SHOULD work with
        mother_dna = random.choice([short_dna, long_dna])
        other_dna = short_dna if mother_dna == long_dna else long_dna
        
        print(f"\nMother DNA length: {len(mother_dna['frame'])}")
        print(f"Other DNA length: {len(other_dna['frame'])}")
        
        # Simulate correct crossover on DNA
        child_dna = copy.deepcopy(mother_dna)
        SEQUENCE_LENGTH = 3
        
        for idx in range(len(child_dna['frame'])):
            if random.random() < 0.5:
                for j in range(SEQUENCE_LENGTH):
                    target_idx = idx + j
                    # Correct bounds checking
                    if target_idx < len(child_dna['frame']) and target_idx < len(other_dna['frame']):
                        child_dna['frame'][target_idx] = other_dna['frame'][target_idx]
                        print(f"Frame crossover: child[{target_idx}] = other[{target_idx}]")
            
            if random.random() < 0.5:
                for j in range(SEQUENCE_LENGTH):
                    target_idx = idx + j
                    if target_idx < len(child_dna['powertrain']) and target_idx < len(other_dna['powertrain']):
                        child_dna['powertrain'][target_idx] = other_dna['powertrain'][target_idx]
                        print(f"Powertrain crossover: child[{target_idx}] = other[{target_idx}]")
        
        print(f"\nResult child DNA: {child_dna}")
        
        # Create new car from the crossed DNA
        try:
            child_car = Car(child_dna)
            print(f"Successfully created child car with {len(child_car.frame)} parts")
        except Exception as e:
            self.fail(f"Failed to create child car from DNA: {e}")

    def test_current_reproduce_method_fails(self):
        """Test that demonstrates the current reproduce method failing."""
        short_car_dna = {
            "frame": ["R"], 
            "powertrain": ["C"]
        }
        short_car = Car(short_car_dna)
        
        long_car_dna = {
            "frame": ["R", "W", "R"], 
            "powertrain": ["C", "D", "G"]
        }
        long_car = Car(long_car_dna)
        
        # This should fail with the current implementation
        with self.assertRaises((IndexError, AttributeError, TypeError)) as context:
            child = Car.reproduce(short_car, long_car)
        
        print(f"Expected failure caught: {context.exception}")

    def test_fix_verification_template(self):
        """Template test that will pass once the reproduce method is fixed."""
        # This test will fail now but should pass after fixing reproduce()
        
        cars_to_test = [
            ({"frame": ["R"], "powertrain": ["C"]}, 
             {"frame": ["R", "W", "R", "R"], "powertrain": ["C", "D", "G", "C"]}),
            ({"frame": ["R", "W"], "powertrain": ["C", "D"]}, 
             {"frame": ["R", "W", "R", "R", "W", "R"], "powertrain": ["C", "D", "G", "D", "C", "G"]}),
            ({"frame": ["W"], "powertrain": ["D"]}, 
             {"frame": ["R", "W", "R"], "powertrain": ["C", "D", "G"]}),
        ]
        
        for short_dna, long_dna in cars_to_test:
            with self.subTest(short=len(short_dna["frame"]), long=len(long_dna["frame"])):
                short_car = Car(short_dna)
                long_car = Car(long_dna)
                
                # Test both orders
                for seed in range(5):  # Test multiple random seeds
                    random.seed(seed)
                    try:
                        child1 = Car.reproduce(short_car, long_car)
                        child2 = Car.reproduce(long_car, short_car)
                        
                        # Basic validations that should always pass
                        self.assertIsNotNone(child1)
                        self.assertIsNotNone(child2) 
                        self.assertGreater(len(child1.frame), 0)
                        self.assertGreater(len(child2.frame), 0)
                        self.assertEqual(len(child1.frame), len(child1.powertrain))
                        self.assertEqual(len(child2.frame), len(child2.powertrain))
                        
                        print(f"Success: {len(short_dna['frame'])} x {len(long_dna['frame'])} -> {len(child1.frame)}, {len(child2.frame)}")
                        
                    except Exception as e:
                        self.fail(f"Reproduction failed for cars of length {len(short_dna['frame'])} and {len(long_dna['frame'])} with seed {seed}: {e}")


if __name__ == "__main__":
    unittest.main(verbosity=2)