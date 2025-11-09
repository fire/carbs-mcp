defmodule Carbs.PythonBridge do
  @moduledoc """
  Low-level Python interop for CARBS using Pythonx.
  Handles Python object lifecycle and data conversion.
  """
  require Logger

  @doc """
  Initialize Python environment and import CARBS.
  CARBS is installed via Pythonx's uv project configuration.
  """
  def init do
    # Import CARBS from the uv-managed Python environment
    python_code = """
from carbs import CARBS
from carbs.utils import CARBSParams, Param, LogSpace, LinearSpace, LogitSpace
from carbs.utils import ObservationInParam
"""
    
    try do
      {_result, _globals} = Pythonx.eval(python_code, %{})
      :ok
    rescue
      e ->
        Logger.error("Failed to initialize Python environment: #{inspect(e)}")
        {:error, :python_init_failed}
    end
  end

  @doc """
  Create a new CARBS optimizer instance.
  Returns serialized state string.
  """
  def create_carbs(config_map, params_list) do
    # Convert :inf atoms to Python-compatible values
    config_json = config_map |> convert_inf_values() |> Jason.encode!()
    params_json = params_list |> convert_inf_values() |> Jason.encode!()
    
    python_code = """
import json
import math

# Parse JSON config and params
config_dict = json.loads('''#{config_json}''')
params_list = json.loads('''#{params_json}''')

# Convert 'inf' strings to float('inf')
def convert_inf(obj):
    if isinstance(obj, dict):
        return {k: convert_inf(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_inf(item) for item in obj]
    elif obj == 'inf':
        return float('inf')
    elif obj == '-inf':
        return float('-inf')
    else:
        return obj

config_dict = convert_inf(config_dict)
params_list = convert_inf(params_list)

# Convert config to CARBSParams
carbs_params = CARBSParams(**config_dict)

# Convert params to Param objects
param_objects = []
for p in params_list:
    space_type = p['space']['type']
    space_config = p['space'].copy()
    del space_config['type']
    
    if space_type == 'LogSpace':
        space = LogSpace(**space_config)
    elif space_type == 'LinearSpace':
        space = LinearSpace(**space_config)
    elif space_type == 'LogitSpace':
        space = LogitSpace(**space_config)
    else:
        raise ValueError(f"Unknown space type: {space_type}")
    
    param = Param(
        name=p['name'],
        space=space,
        search_center=p['search_center']
    )
    param_objects.append(param)

# Create CARBS instance
carbs = CARBS(carbs_params, param_objects)

# Serialize immediately
serialized = carbs.serialize()
serialized
"""
    
    try do
      {_result, globals} = Pythonx.eval(python_code, %{})
      serialized = Pythonx.decode(Map.get(globals, "serialized"))
      
      if serialized do
        {:ok, serialized}
      else
        Logger.error("No serialized state returned from Python")
        {:error, :carbs_creation_failed}
      end
    rescue
      e ->
        Logger.error("Failed to create CARBS instance: #{inspect(e)}")
        {:error, :carbs_creation_failed}
    end
  end

  @doc """
  Call suggest on a CARBS instance.
  Note: serialized_state should be a base64 serialized CARBS string.
  """
  def suggest(serialized_state, suggestion_id \\ nil, is_suggestion_remembered \\ true) do
    sid_str = if suggestion_id, do: "\"#{suggestion_id}\"", else: "None"
    remembered_str = if is_suggestion_remembered, do: "True", else: "False"
    # Base64 strings are safe, but use triple quotes for maximum safety
    # Escape any triple quotes that might exist (unlikely in base64)
    escaped_state = String.replace(serialized_state, "\"\"\"", "\\\"\\\"\\\"")
    
    python_code = """
import json
import base64

# Deserialize CARBS instance
serialized = """#{escaped_state}"""
carbs = CARBS.load_from_string(serialized, is_wandb_logging_enabled=False)

suggestion_id = #{sid_str}
is_remembered = #{remembered_str}

result = carbs.suggest(suggestion_id=suggestion_id, is_suggestion_remembered=is_remembered)

# Convert to dict
result_dict = {
    'suggestion': result.suggestion,
    'log': result.log if hasattr(result, 'log') else {}
}

# Also serialize the updated state
updated_serialized = carbs.serialize()

result_data = {
    'result': result_dict,
    'serialized': updated_serialized
}
result_data
"""
    
    try do
      {_result, globals} = Pythonx.eval(python_code, %{})
      result_data = Pythonx.decode(Map.get(globals, "result_data"))
      
      if result_data do
        result_dict = Map.get(result_data, "result") || Map.get(result_data, :result)
        updated_serialized = Map.get(result_data, "serialized") || Map.get(result_data, :serialized)
        {:ok, decode_from_python(result_dict), updated_serialized}
      else
        {:error, :suggest_failed}
      end
    rescue
      e ->
        Logger.error("Failed to get suggestion: #{inspect(e)}")
        {:error, :suggest_failed}
    end
  end

  @doc """
  Call observe on a CARBS instance.
  Note: serialized_state should be a base64 serialized CARBS string.
  """
  def observe(serialized_state, observation) do
    obs_json = Jason.encode!(observation.input)
    # Base64 strings are safe, but use triple quotes for maximum safety
    # Escape any triple quotes that might exist (unlikely in base64)
    escaped_state = String.replace(serialized_state, "\"\"\"", "\\\"\\\"\\\"")
    
    python_code = """
import json

# Deserialize CARBS instance
serialized = """#{escaped_state}"""
carbs = CARBS.load_from_string(serialized, is_wandb_logging_enabled=False)

obs_input = json.loads('''#{obs_json}''')
obs_output = #{observation.output}
obs_cost = #{observation.cost}
obs_is_failure = #{observation.is_failure}

obs = ObservationInParam(
    input=obs_input,
    output=obs_output,
    cost=obs_cost,
    is_failure=obs_is_failure
)

result = carbs.observe(obs)

# Convert to dict
result_dict = {
    'logs': result.logs if hasattr(result, 'logs') else {}
}

# Also serialize the updated state
updated_serialized = carbs.serialize()

result_data = {
    'result': result_dict,
    'serialized': updated_serialized
}
result_data
"""
    
    try do
      {_result, globals} = Pythonx.eval(python_code, %{})
      result_data = Pythonx.decode(Map.get(globals, "result_data"))
      
      if result_data do
        result_dict = Map.get(result_data, "result") || Map.get(result_data, :result)
        updated_serialized = Map.get(result_data, "serialized") || Map.get(result_data, :serialized)
        {:ok, decode_from_python(result_dict), updated_serialized}
      else
        {:error, :observe_failed}
      end
    rescue
      e ->
        Logger.error("Failed to observe: #{inspect(e)}")
        {:error, :observe_failed}
    end
  end


  # Helper functions for encoding/decoding

  defp encode_to_python(term) when is_map(term) do
    entries = 
      term
      |> Enum.map(fn {k, v} -> "'#{k}': #{encode_to_python(v)}" end)
      |> Enum.join(", ")
    "{#{entries}}"
  end

  defp encode_to_python(term) when is_list(term) do
    entries = 
      term
      |> Enum.map(&encode_to_python/1)
      |> Enum.join(", ")
    "[#{entries}]"
  end

  defp encode_to_python(term) when is_atom(term) do
    "'#{term}'"
  end

  defp encode_to_python(term) when is_binary(term) do
    escaped = String.replace(term, "'", "\\'")
    "r'#{escaped}'"
  end

  defp encode_to_python(term) when is_integer(term) do
    Integer.to_string(term)
  end

  defp encode_to_python(term) when is_float(term) do
    Float.to_string(term)
  end

  defp encode_to_python(term) when is_boolean(term) do
    if term, do: "True", else: "False"
  end

  defp encode_to_python(nil) do
    "None"
  end

  defp decode_from_python(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {decode_key(k), decode_from_python(v)} end)
    |> Enum.into(%{})
  end

  defp decode_from_python(term) when is_list(term) do
    Enum.map(term, &decode_from_python/1)
  end

  defp decode_from_python(term) when is_binary(term) do
    term
  end

  defp decode_from_python(term) when is_number(term) do
    term
  end

  defp decode_from_python(term) when is_boolean(term) do
    term
  end

  defp decode_from_python(nil) do
    nil
  end

  defp decode_from_python(term) do
    # For unknown types, try to convert to string
    to_string(term)
  end

  defp decode_key(k) when is_binary(k) do
    String.to_atom(k)
  end

  defp decode_key(k) when is_atom(k) do
    k
  end

  defp decode_key(k) do
    k
  end

  # Convert :inf atoms to Python-compatible float('inf') representation
  defp convert_inf_values(term) when is_map(term) do
    Enum.map(term, fn {k, v} -> {k, convert_inf_values(v)} end)
    |> Enum.into(%{})
  end

  defp convert_inf_values(term) when is_list(term) do
    Enum.map(term, &convert_inf_values/1)
  end

  defp convert_inf_values(:inf) do
    "inf"
  end

  defp convert_inf_values(:"-inf") do
    "-inf"
  end

  defp convert_inf_values(value), do: value
end

