"""vroomon.main module."""

from loguru import logger

from vroomon.car.car import Car
from vroomon.ground import Ground
from vroomon.simulation import Simulation
from vroomon.population.population import (
    initialize_population,
    evolve_population,
    score_population,
)

CAR_DNA = {
    "powertrain": ["C", "G", "D", "D", "G"],  # C = Cylinder, G = Gear, D = DriveShaft
    "frame": ["R", "W", "R", "R", "W"],  # R = Rectangle, W = Wheel
}


def test_car():
    """Test that a basic Car has a positive score on default ground."""
    car = Car(CAR_DNA)
    ground = Ground()
    simulation = Simulation()
    score = simulation.score_car(car=car, ground=ground, visualize=True)
    assert score > 0, "Car should have a positive score on the ground"


def main():
    """Run the evolutionary simulation and display best car results."""
    # Evolutionary run: maintain a population, score and reproduce
    population_size = 20
    dna_length = 5
    generations = 10
    # initialize population
    pop = initialize_population(population_size, dna_length)
    ground = Ground()
    sim = Simulation()
    # evolve over generations
    for gen in range(generations):
        pop = evolve_population(
            pop, retain_ratio=0.5, mutation_rate=0.1, ground=ground, simulation=sim
        )
        scored = score_population(pop, ground, sim)
        best_car, best_score = max(scored, key=lambda x: x[1])
        logger.info(f"Generation {gen+1}/{generations}, Best score: {best_score}")
    # run simulation with visualization for the best car
    logger.info(f"Best car DNA: {best_car}")
    final_score = sim.score_car(best_car, ground, visualize=True)
    logger.info(f"Final best score: {final_score}")


if __name__ == "__main__":
    main()
