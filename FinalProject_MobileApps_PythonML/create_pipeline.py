import coremltools as ct
from coremltools.models.pipeline import Pipeline

# Load individual models
mlmodel_action = ct.models.MLModel("ActionCodeModel.mlmodel")
mlmodel_bust = ct.models.MLModel("BustProbabilityModel.mlmodel")
mlmodel_improve = ct.models.MLModel("ImproveHandModel.mlmodel")
mlmodel_dealer = ct.models.MLModel("DealerBeatModel.mlmodel")

# All models share the same input features.
input_features = [f.name for f in mlmodel_action._spec.description.input]

# Define final output feature names in the order that matches the models we add
final_outputs = [
    "action_code",
    "BustProbabilityIfHit",
    "ImproveHandWithoutBustingIfHit",
    "IfStandOddsDealersSecondCardMakesThemBeatUs"
]

# Create the pipeline
pipeline = Pipeline(input_features=input_features, output_features=final_outputs)

# Add model specs to the pipeline
pipeline.add_model(mlmodel_action._spec)
pipeline.add_model(mlmodel_bust._spec)
pipeline.add_model(mlmodel_improve._spec)
pipeline.add_model(mlmodel_dealer._spec)

pipeline_spec = pipeline.spec

# Each model should take the pipeline inputs directly and produce a single named output.
for i, model_name in enumerate(final_outputs):
    model_spec = pipeline_spec.pipeline.models[i]

    # Clear current inputs/outputs
    del model_spec.description.input[:]
    del model_spec.description.output[:]

    # Set model inputs to be the pipeline's top-level inputs
    for feat in input_features:
        inp = model_spec.description.input.add()
        inp.name = feat
        original_input = mlmodel_action._spec.description.input[0]
        inp.type.CopyFrom(original_input.type)

    # Set model output
    outp = model_spec.description.output.add()
    outp.name = model_name
    if i == 0:
        ref_model = mlmodel_action._spec
    elif i == 1:
        ref_model = mlmodel_bust._spec
    elif i == 2:
        ref_model = mlmodel_improve._spec
    else:
        ref_model = mlmodel_dealer._spec

    original_output = ref_model.description.output[0]
    outp.type.CopyFrom(original_output.type)

# Clear and redefine the top-level input/output if necessary
del pipeline_spec.description.input[:]
del pipeline_spec.description.output[:]

for feat in input_features:
    pinp = pipeline_spec.description.input.add()
    pinp.name = feat
    # Copy type from the mlmodel_action input as a reference
    original_input = mlmodel_action._spec.description.input[0]
    pinp.type.CopyFrom(original_input.type)

for out_name in final_outputs:
    pout = pipeline_spec.description.output.add()
    pout.name = out_name
    if out_name == "action_code":
        ref_spec = mlmodel_action._spec
    elif out_name == "BustProbabilityIfHit":
        ref_spec = mlmodel_bust._spec
    elif out_name == "ImproveHandWithoutBustingIfHit":
        ref_spec = mlmodel_improve._spec
    else:
        ref_spec = mlmodel_dealer._spec

    pout.type.CopyFrom(ref_spec.description.output[0].type)

# Convert the pipeline spec back to an MLModel
pipeline_model = ct.models.MLModel(pipeline_spec)
pipeline_model.save("BlackJackPipeline.mlmodel")