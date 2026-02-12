class PipelineOrchestrator:
    def __init__(self, params):
        self.params = params

    def run(self):
        # Step 1: Data Preprocessing
        data_preprocessor = DataPreprocessor(self.params)
        preprocessed_data = data_preprocessor.preprocess()

        # Step 2: Model Training
        model_trainer = ModelTrainer(self.params)
        model = model_trainer.train(preprocessed_data)

        # Step 3: Model Evaluation
        model_evaluator = ModelEvaluator(self.params)
        evaluation_results = model_evaluator.evaluate(model, preprocessed_data)

        # Step 4: Save Results
        results_saver = ResultsSaver(self.params)
        results_saver.save(evaluation_results)