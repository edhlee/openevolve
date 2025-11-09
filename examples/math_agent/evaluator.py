"""
Evaluator for the Math Agent.

This evaluator tests the evolved program against a dataset of math problems
across multiple categories and difficulty levels.
"""

import sys
import os
import json
import time
from importlib import __import__
from typing import Dict, Any, List


def load_problems(problems_file: str = "problems.json") -> List[Dict[str, Any]]:
    """Load the math problems dataset."""
    # Get the directory of this evaluator file
    evaluator_dir = os.path.dirname(os.path.abspath(__file__))
    problems_path = os.path.join(evaluator_dir, problems_file)

    with open(problems_path, "r") as f:
        return json.load(f)


def evaluate(program_path: str) -> Dict[str, Any]:
    """
    Evaluate the program against all math problems.

    Args:
        program_path: Path to the program to evaluate

    Returns:
        Dictionary containing evaluation metrics
    """
    try:
        # Import the program
        abs_program_path = os.path.abspath(program_path)
        program_dir = os.path.dirname(abs_program_path)
        module_name = os.path.splitext(os.path.basename(program_path))[0]

        program = None
        try:
            sys.path.insert(0, program_dir)
            program = __import__(module_name)
        except Exception as err:
            raise err
        finally:
            if program_dir in sys.path:
                sys.path.remove(program_dir)

        # Load problems
        problems = load_problems()

        # Track results
        total_problems = len(problems)
        correct = 0
        category_scores = {}
        difficulty_scores = {}
        errors = []
        total_time = 0.0

        # Test each problem
        for problem_data in problems:
            problem_id = problem_data["id"]
            problem = problem_data["problem"]
            category = problem_data["category"]
            difficulty = problem_data["difficulty"]
            expected_answer = problem_data["answer"]
            tolerance = problem_data["tolerance"]

            # Initialize category and difficulty tracking
            if category not in category_scores:
                category_scores[category] = {"correct": 0, "total": 0}
            if difficulty not in difficulty_scores:
                difficulty_scores[difficulty] = {"correct": 0, "total": 0}

            category_scores[category]["total"] += 1
            difficulty_scores[difficulty]["total"] += 1

            try:
                # Time the solution
                start_time = time.time()
                answer = program.solve_problem(problem, category)
                end_time = time.time()
                elapsed = end_time - start_time
                total_time += elapsed

                # Check if answer is correct (within tolerance)
                if abs(answer - expected_answer) <= tolerance:
                    correct += 1
                    category_scores[category]["correct"] += 1
                    difficulty_scores[difficulty]["correct"] += 1
                else:
                    errors.append({
                        "id": problem_id,
                        "category": category,
                        "difficulty": difficulty,
                        "problem": problem,
                        "expected": expected_answer,
                        "got": answer,
                        "error": f"Wrong answer: expected {expected_answer}, got {answer}"
                    })

            except Exception as e:
                errors.append({
                    "id": problem_id,
                    "category": category,
                    "difficulty": difficulty,
                    "problem": problem,
                    "expected": expected_answer,
                    "got": None,
                    "error": str(e)
                })

        # Calculate overall accuracy
        accuracy = correct / total_problems if total_problems > 0 else 0.0

        # Calculate category accuracies
        category_accuracies = {
            cat: scores["correct"] / scores["total"] if scores["total"] > 0 else 0.0
            for cat, scores in category_scores.items()
        }

        # Calculate difficulty accuracies
        difficulty_accuracies = {
            diff: scores["correct"] / scores["total"] if scores["total"] > 0 else 0.0
            for diff, scores in difficulty_scores.items()
        }

        # Combined score (weighted by difficulty)
        difficulty_weights = {"easy": 1.0, "medium": 2.0, "hard": 3.0}
        weighted_score = sum(
            difficulty_accuracies.get(diff, 0.0) * weight
            for diff, weight in difficulty_weights.items()
        )
        max_weighted_score = sum(difficulty_weights.values())
        combined_score = weighted_score / max_weighted_score if max_weighted_score > 0 else 0.0

        # Calculate complexity (based on code analysis)
        # Read the program file to estimate complexity
        with open(abs_program_path, "r") as f:
            code = f.read()
            # Simple complexity metric: lines of code in evolve block
            evolve_block = ""
            if "# EVOLVE-BLOCK-START" in code and "# EVOLVE-BLOCK-END" in code:
                start = code.index("# EVOLVE-BLOCK-START")
                end = code.index("# EVOLVE-BLOCK-END")
                evolve_block = code[start:end]

            lines = [line for line in evolve_block.split("\n") if line.strip() and not line.strip().startswith("#")]
            complexity = len(lines)

        return {
            "combined_score": float(combined_score),
            "accuracy": float(accuracy),
            "correct": int(correct),
            "total": int(total_problems),
            "category_accuracies": category_accuracies,
            "difficulty_accuracies": difficulty_accuracies,
            "avg_time_per_problem": float(total_time / total_problems if total_problems > 0 else 0.0),
            "total_time": float(total_time),
            "complexity": int(complexity),
            "num_errors": len(errors),
            "sample_errors": errors[:5] if errors else []  # Include up to 5 sample errors
        }

    except Exception as e:
        return {
            "combined_score": 0.0,
            "accuracy": 0.0,
            "error": str(e)
        }
