import torch


class Evaluator:
    def __init__(self, model: torch.nn.Module, device: torch.device):
        self.model = model
        self.device = device
    
    def evaluate(self, data_loader: DataLoader) -> PredictionResult:
        self.model.eval()
        y_true = []
        y_pred = []
        y_prob = []
        
        with torch.no_grad():
            for inputs, labels in data_loader:
                inputs, labels = inputs.to(self.device), labels.to(self.device)
                outputs = self.model(inputs)
                probabilities = torch.softmax(outputs, dim=1)
                predicted_labels = torch.argmax(probabilities, dim=1)
                
                y_true.append(labels.cpu())
                y_pred.append(predicted_labels.cpu())
                y_prob.append(probabilities.cpu())
        
        return PredictionResult(
            y_true=torch.cat(y_true),
            y_pred=torch.cat(y_pred),
            y_prob=torch.cat(y_prob)
        )