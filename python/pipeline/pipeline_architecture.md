JSON → Pipeline (dataclass)
      → PipelineRunner
          → BranchRunner (für jeden Branch)
              → ModelFactory, Trainer
              → ExperimentTracker.log_branch_result(...)

PipelineRunner
├── __init__(pipeline_config, dataset_builder, tracker)
├── run() → dict
└── _build_dataloaders() → TrainValTestDataLoaders

BranchRunner
├── __init__(pipeline_id, branch_config, data, tracker, output_path)
├── run() → dict
├── _branch_output_dir() → Path
├── _get_device() → torch.device
├── _save_model(model, path)
├── _save_plots(history, path)
└── _save_metrics_json(metrics, path)

ExperimentTracker
├── __init__()
├── log_branch_result(pipeline_id, branch_id, config, metrics, artifacts)
└── export_pipeline_summary(pipeline_id, path)

Trainer
├── __init__(model, config, device)
├── train(train_loader, val_loader) → TrainingHistory
├── test(test_loader) → PredictionResult
├── _build_optimizer()
├── _build_scheduler()

ModelFactory
├── build(model_arch) → nn.Module
├── _freeze_weights(model, strategy)
├── _modify_input_layer(model, num_channels)
└── _modify_output_layer(model, num_classes)

DatasetBuilder
└── build(data_path, split_ratio, batch_size, num_workers) → TrainValTestDataLoaders