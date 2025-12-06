# Divide and recycle

Simply take a picture of the garbage and the app would tell you which type of garbage that is. The goal is to make recycling easier.

## Model

Base model used is MobileNetV3 - Small.

## Dataset

[See dataset](https://www.kaggle.com/datasets/viswaprakash1990/garbage-detection?select=GARBAGE+CLASSIFICATION)

Used dataset contains 6 classes of garbage:

- Biodegradable
- Cardboard
- Glass
- Metal
- Paper
- Plastic

### Preparation

[garbage_dataset](https://github.com/makedonkabinova/divide_and_recycle/tree/main/model/garbage_dataset) -> [data_prepared](https://github.com/makedonkabinova/divide_and_recycle/tree/main/model/data_prepared)

Train - 80%
Validation - 10%
Test - 10%

## Training

First freezing the base, because MobileNetV3 already performs pretty good on the base features, so we freeze all the layers, 
weights are not updated, only weights on the Dense layer are updated (last).

Afterwards unfreezing last 20 layers of base model. Trained on 10 epochs and model overfitted. So instead, I decided to go with 5 epochs.

## Results

Loss analysis:

- Train: 0.3072
- Validation: 0.2916
- Test: 0.3161

Accuracy analysis:

- Train: 89.08%
- Validation: 89.68%
- Test: 88.55%