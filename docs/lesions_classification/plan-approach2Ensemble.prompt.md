Plan: Build Approach 2 Ensemble

Outline two-branch soft-voting ensemble with modular hooks: define branch configs, train/evaluate separately, add shared registry, and implement an inference-time voter that can later be swapped for a fusion layer.

Steps
1. Define ensemble config/data contracts in docs/machine_learning/multibranch_architecture.md and a new python/dualbranch/ensemble_config.py describing branch ids, model/backbone, filters/transforms, checkpoint paths, and weights for voting.
2. Extend dataset orchestration in python/dualbranch/ham10000_dataset_manager.py to emit per-branch dataloaders (shared splits, branch-specific transforms/filters) and document usage in docs/machine_learning/filter_experiments.md.
3. Factor training runner from python/dualbranch/ResNetFinetuneTrain.py into a reusable train_branch(config) that saves checkpoints/metrics under a branch-aware directory; add CLI entry to launch two branch trainings in parallel.
4. Implement inference utilities in python/dualbranch for load_branch_model(config) and soft_vote_predict(models, weights, dataloader) producing per-image probabilities/labels; log ensemble metrics alongside per-branch results.
5. Add minimal doc/playbook updates in docs/machine_learning/machine_learning.md to describe running Approach 2 end-to-end (prepare config, train branches, run ensemble eval) and note the seam where a future fusion layer would replace the voter.

Further Considerations
1. Assignments: Person A owns data/config + training refactor; Person B owns inference voter + docs—agree on the ensemble config schema first.
