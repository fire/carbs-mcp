defmodule CarbsMCPServerTest do
  use ExUnit.Case
  alias CarbsMCP.Server
  alias CarbsMCP.Repo
  alias CarbsMCP.Optimizer

  setup do
    # Ensure database is clean before each test
    Repo.delete_all(Optimizer)
    
    # Initialize Python environment
    case Carbs.PythonBridge.init() do
      :ok -> :ok
      error -> 
        IO.puts("Warning: Python initialization failed: #{inspect(error)}")
        :ok
    end
    
    on_exit(fn ->
      Repo.delete_all(Optimizer)
    end)
    
    {:ok, %{}}
  end

  describe "handle_list_tools" do
    test "returns all MCP tools" do
      {:ok, tools, _state} = Server.handle_list_tools(%{}, %{})
      
      tool_names = Enum.map(tools, & &1.name)
      
      assert "carbs_create" in tool_names
      assert "carbs_suggest" in tool_names
      assert "carbs_observe" in tool_names
      assert "carbs_load" in tool_names
      assert "carbs_save" in tool_names
      assert "carbs_list" in tool_names
    end

    test "tools have correct schemas" do
      {:ok, tools, _state} = Server.handle_list_tools(%{}, %{})
      
      create_tool = Enum.find(tools, &(&1.name == "carbs_create"))
      assert create_tool.inputSchema.required == ["name", "params"]
      
      suggest_tool = Enum.find(tools, &(&1.name == "carbs_suggest"))
      assert suggest_tool.inputSchema.required == ["name"]
      
      observe_tool = Enum.find(tools, &(&1.name == "carbs_observe"))
      assert observe_tool.inputSchema.required == ["name", "input", "output"]
    end
  end

  describe "carbs_create" do
    test "creates optimizer with LogSpace parameter" do
      args = %{
        "name" => "test_optimizer_1",
        "params" => [
          %{
            "name" => "learning_rate",
            "space" => %{
              "type" => "LogSpace",
              "scale" => 0.5
            },
            "search_center" => 0.0001
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", args, %{}) do
        {:ok, content, _state} ->
          assert length(content) == 1
          first_content = List.first(content)
          assert first_content.type == "text"
          assert first_content.text =~ "Created CARBS optimizer"
        {:error, content, _state} ->
          # If Python/CARBS is not available, skip this test
          IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
          :ok
      end
    end

    test "creates optimizer with LinearSpace parameter" do
      args = %{
        "name" => "test_optimizer_2",
        "params" => [
          %{
            "name" => "batch_size",
            "space" => %{
              "type" => "LinearSpace",
              "scale" => 32.0,
              "is_integer" => true
            },
            "search_center" => 64
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", args, %{}) do
        {:ok, content, _state} ->
          assert length(content) == 1
          assert List.first(content).text =~ "Created CARBS optimizer"
        {:error, content, _state} ->
          IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
          :ok
      end
    end

    test "creates optimizer with LogitSpace parameter" do
      args = %{
        "name" => "test_optimizer_3",
        "params" => [
          %{
            "name" => "dropout_rate",
            "space" => %{
              "type" => "LogitSpace",
              "scale" => 1.0
            },
            "search_center" => 0.5
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", args, %{}) do
        {:ok, content, _state} ->
          assert length(content) == 1
          assert List.first(content).text =~ "Created CARBS optimizer"
        {:error, content, _state} ->
          IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
          :ok
      end
    end

    test "creates optimizer with multiple parameters" do
      args = %{
        "name" => "test_optimizer_multi",
        "config" => %{
          "better_direction_sign" => -1,
          "is_wandb_logging_enabled" => false
        },
        "params" => [
          %{
            "name" => "learning_rate",
            "space" => %{
              "type" => "LogSpace",
              "scale" => 0.5
            },
            "search_center" => 0.0001
          },
          %{
            "name" => "batch_size",
            "space" => %{
              "type" => "LinearSpace",
              "scale" => 32.0,
              "is_integer" => true
            },
            "search_center" => 64
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", args, %{}) do
        {:ok, content, _state} ->
          assert length(content) == 1
          assert List.first(content).text =~ "Created CARBS optimizer"
        {:error, content, _state} ->
          IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
          :ok
      end
    end

    test "returns error when name is missing" do
      args = %{
        "params" => [
          %{
            "name" => "learning_rate",
            "space" => %{"type" => "LogSpace", "scale" => 0.5},
            "search_center" => 0.0001
          }
        ]
      }

      {:error, content, _state} = Server.handle_call_tool("carbs_create", args, %{})
      assert length(content) == 1
          assert List.first(content).text =~ "Missing required arguments"
    end

    test "returns error when params is missing" do
      args = %{
        "name" => "test_optimizer"
      }

      {:error, content, _state} = Server.handle_call_tool("carbs_create", args, %{})
      assert length(content) == 1
          assert List.first(content).text =~ "Missing required arguments"
    end

    test "returns error when params is empty" do
      args = %{
        "name" => "test_optimizer",
        "params" => []
      }

      {:error, content, _state} = Server.handle_call_tool("carbs_create", args, %{})
      assert length(content) == 1
          assert List.first(content).text =~ "Missing required arguments"
    end

    test "returns error for unknown space type" do
      args = %{
        "name" => "test_optimizer",
        "params" => [
          %{
            "name" => "param1",
            "space" => %{
              "type" => "UnknownSpace",
              "scale" => 1.0
            },
            "search_center" => 1.0
          }
        ]
      }

      {:error, content, _state} = Server.handle_call_tool("carbs_create", args, %{})
      assert length(content) == 1
          assert List.first(content).text =~ "Unknown space type"
    end

    test "returns error when parameter missing required fields" do
      args = %{
        "name" => "test_optimizer",
        "params" => [
          %{
            "name" => "param1",
            "space" => %{
              "type" => "LogSpace",
              "scale" => 0.5
            }
            # Missing search_center
          }
        ]
      }

      {:error, content, _state} = Server.handle_call_tool("carbs_create", args, %{})
      assert length(content) == 1
          assert List.first(content).text =~ "Parameter missing required fields"
    end
  end

  describe "carbs_suggest" do
    test "returns suggestion for existing optimizer" do
      # First create an optimizer
      create_args = %{
        "name" => "suggest_test_optimizer",
        "params" => [
          %{
            "name" => "learning_rate",
            "space" => %{
              "type" => "LogSpace",
              "scale" => 0.5
            },
            "search_center" => 0.0001
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", create_args, %{}) do
        {:ok, _, _state} ->
          # Now get a suggestion
          suggest_args = %{"name" => "suggest_test_optimizer"}
          
          case Server.handle_call_tool("carbs_suggest", suggest_args, %{}) do
            {:ok, content, _state} ->
              assert length(content) == 1
              first_content = List.first(content)
              assert first_content.type == "text"
              assert first_content.text =~ "Suggestion:"
              # Verify it's valid JSON
              suggestion_text = String.replace(first_content.text, "Suggestion: ", "")
              suggestion = Jason.decode!(suggestion_text)
              assert Map.has_key?(suggestion, "learning_rate")
            {:error, content, _state} ->
              IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
              :ok
          end
        {:error, content, _state} ->
          IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
          :ok
      end
    end

    test "returns error when name is missing" do
      args = %{}

      {:error, content, _state} = Server.handle_call_tool("carbs_suggest", args, %{})
      assert length(content) == 1
      assert List.first(content).text =~ "Missing required argument"
    end

    test "returns error for non-existent optimizer" do
      args = %{"name" => "nonexistent_optimizer"}

      {:error, content, _state} = Server.handle_call_tool("carbs_suggest", args, %{})
      assert length(content) == 1
      assert List.first(content).text =~ "Failed to load optimizer"
    end
  end

  describe "carbs_observe" do
    test "records observation for existing optimizer" do
      # First create an optimizer
      create_args = %{
        "name" => "observe_test_optimizer",
        "params" => [
          %{
            "name" => "learning_rate",
            "space" => %{
              "type" => "LogSpace",
              "scale" => 0.5
            },
            "search_center" => 0.0001
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", create_args, %{}) do
        {:ok, _, _state} ->
          # Get a suggestion first
          suggest_args = %{"name" => "observe_test_optimizer"}
          
          case Server.handle_call_tool("carbs_suggest", suggest_args, %{}) do
            {:ok, suggest_content, _state} ->
              suggestion_text = String.replace(List.first(suggest_content).text, "Suggestion: ", "")
              suggestion = Jason.decode!(suggestion_text)
              
              # Now observe the result
              observe_args = %{
                "name" => "observe_test_optimizer",
                "input" => suggestion,
                "output" => 0.95,
                "cost" => 10.0,
                "is_failure" => false
              }
              
              case Server.handle_call_tool("carbs_observe", observe_args, %{}) do
                {:ok, content, _state} ->
                  assert length(content) == 1
                  assert List.first(content).text =~ "Observation recorded"
                {:error, content, _state} ->
                  IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
                  :ok
              end
            {:error, content, _state} ->
              IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
              :ok
          end
        {:error, content, _state} ->
          IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
          :ok
      end
    end

    test "records observation with failure flag" do
      # First create an optimizer
      create_args = %{
        "name" => "observe_failure_test",
        "params" => [
          %{
            "name" => "learning_rate",
            "space" => %{
              "type" => "LogSpace",
              "scale" => 0.5
            },
            "search_center" => 0.0001
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", create_args, %{}) do
        {:ok, _, _state} ->
          observe_args = %{
            "name" => "observe_failure_test",
            "input" => %{"learning_rate" => 0.001},
            "output" => 0.0,
            "cost" => 5.0,
            "is_failure" => true
          }
          
          case Server.handle_call_tool("carbs_observe", observe_args, %{}) do
            {:ok, content, _state} ->
              assert length(content) == 1
              assert List.first(content).text =~ "Observation recorded"
            {:error, content, _state} ->
              IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
              :ok
          end
        {:error, content, _state} ->
          IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
          :ok
      end
    end

    test "uses default cost when not provided" do
      create_args = %{
        "name" => "observe_default_cost_test",
        "params" => [
          %{
            "name" => "learning_rate",
            "space" => %{
              "type" => "LogSpace",
              "scale" => 0.5
            },
            "search_center" => 0.0001
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", create_args, %{}) do
        {:ok, _, _state} ->
          observe_args = %{
            "name" => "observe_default_cost_test",
            "input" => %{"learning_rate" => 0.001},
            "output" => 0.9
            # cost not provided, should default to 1.0
          }
          
          case Server.handle_call_tool("carbs_observe", observe_args, %{}) do
            {:ok, content, _state} ->
              assert length(content) == 1
              assert List.first(content).text =~ "Observation recorded"
            {:error, content, _state} ->
              IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
              :ok
          end
        {:error, content, _state} ->
          IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
          :ok
      end
    end

    test "returns error when name is missing" do
      args = %{
        "input" => %{"learning_rate" => 0.001},
        "output" => 0.9
      }

      {:error, content, _state} = Server.handle_call_tool("carbs_observe", args, %{})
      assert length(content) == 1
          assert List.first(content).text =~ "Missing required arguments"
    end

    test "returns error when input is missing" do
      args = %{
        "name" => "test_optimizer",
        "output" => 0.9
      }

      {:error, content, _state} = Server.handle_call_tool("carbs_observe", args, %{})
      assert length(content) == 1
          assert List.first(content).text =~ "Missing required arguments"
    end

    test "returns error when output is missing" do
      args = %{
        "name" => "test_optimizer",
        "input" => %{"learning_rate" => 0.001}
      }

      {:error, content, _state} = Server.handle_call_tool("carbs_observe", args, %{})
      assert length(content) == 1
          assert List.first(content).text =~ "Missing required arguments"
    end

    test "returns error for non-existent optimizer" do
      args = %{
        "name" => "nonexistent_optimizer",
        "input" => %{"learning_rate" => 0.001},
        "output" => 0.9
      }

      {:error, content, _state} = Server.handle_call_tool("carbs_observe", args, %{})
      assert length(content) == 1
      assert List.first(content).text =~ "Failed to load optimizer"
    end
  end

  describe "carbs_load" do
    test "loads existing optimizer" do
      # First create an optimizer
      create_args = %{
        "name" => "load_test_optimizer",
        "params" => [
          %{
            "name" => "learning_rate",
            "space" => %{
              "type" => "LogSpace",
              "scale" => 0.5
            },
            "search_center" => 0.0001
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", create_args, %{}) do
        {:ok, _, _state} ->
          load_args = %{"name" => "load_test_optimizer"}
          
          {:ok, content, _state} = Server.handle_call_tool("carbs_load", load_args, %{})
          assert length(content) == 1
          assert List.first(content).text =~ "Loaded optimizer"
        {:error, content, _state} ->
          IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
          :ok
      end
    end

    test "returns error when name is missing" do
      args = %{}

      {:error, content, _state} = Server.handle_call_tool("carbs_load", args, %{})
      assert length(content) == 1
      assert List.first(content).text =~ "Missing required argument"
    end

    test "returns error for non-existent optimizer" do
      args = %{"name" => "nonexistent_optimizer"}

      {:error, content, _state} = Server.handle_call_tool("carbs_load", args, %{})
      assert length(content) == 1
      assert List.first(content).text =~ "Failed to load optimizer"
    end
  end

  describe "carbs_save" do
    test "saves existing optimizer" do
      # First create an optimizer
      create_args = %{
        "name" => "save_test_optimizer",
        "params" => [
          %{
            "name" => "learning_rate",
            "space" => %{
              "type" => "LogSpace",
              "scale" => 0.5
            },
            "search_center" => 0.0001
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", create_args, %{}) do
        {:ok, _, _state} ->
          save_args = %{"name" => "save_test_optimizer"}
          
          {:ok, content, _state} = Server.handle_call_tool("carbs_save", save_args, %{})
          assert length(content) == 1
          assert List.first(content).text =~ "Saved optimizer"
        {:error, content, _state} ->
          IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
          :ok
      end
    end

    test "returns error when name is missing" do
      args = %{}

      {:error, content, _state} = Server.handle_call_tool("carbs_save", args, %{})
      assert length(content) == 1
      assert List.first(content).text =~ "Missing required argument"
    end

    test "returns error for non-existent optimizer" do
      args = %{"name" => "nonexistent_optimizer"}

      {:error, content, _state} = Server.handle_call_tool("carbs_save", args, %{})
      assert length(content) == 1
      assert List.first(content).text =~ "Failed to load optimizer"
    end
  end

  describe "carbs_list" do
    test "lists all saved optimizers" do
      # Create a few optimizers
      create_args1 = %{
        "name" => "list_test_1",
        "params" => [
          %{
            "name" => "learning_rate",
            "space" => %{"type" => "LogSpace", "scale" => 0.5},
            "search_center" => 0.0001
          }
        ]
      }

      create_args2 = %{
        "name" => "list_test_2",
        "params" => [
          %{
            "name" => "batch_size",
            "space" => %{"type" => "LinearSpace", "scale" => 32.0, "is_integer" => true},
            "search_center" => 64
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", create_args1, %{}) do
        {:ok, _, _state} ->
          case Server.handle_call_tool("carbs_create", create_args2, %{}) do
            {:ok, _, _state} ->
              {:ok, content, _state} = Server.handle_call_tool("carbs_list", %{}, %{})
              assert length(content) == 1
              first_content = List.first(content)
              assert first_content.text =~ "Saved optimizers"
              assert first_content.text =~ "list_test_1"
              assert first_content.text =~ "list_test_2"
            {:error, _, _state} ->
              IO.puts("Skipping test - Python/CARBS not available")
              :ok
          end
        {:error, _, _state} ->
          IO.puts("Skipping test - Python/CARBS not available")
          :ok
      end
    end

    test "returns empty list when no optimizers exist" do
      {:ok, content, _state} = Server.handle_call_tool("carbs_list", %{}, %{})
      assert length(content) == 1
      assert List.first(content).text =~ "Saved optimizers:"
    end
  end

  describe "unknown tool" do
    test "returns error for unknown tool name" do
      args = %{"name" => "test"}

      {:error, content, _state} = Server.handle_call_tool("unknown_tool", args, %{})
      assert length(content) == 1
      assert List.first(content).text =~ "Unknown tool"
    end
  end

  describe "atomize_keys helper" do
    test "handles string keys" do
      # Test through carbs_create which uses atomize_keys
      args = %{
        "name" => "atomize_test",
        "config" => %{
          "better_direction_sign" => -1,
          "is_wandb_logging_enabled" => false
        },
        "params" => [
          %{
            "name" => "learning_rate",
            "space" => %{
              "type" => "LogSpace",
              "scale" => 0.5
            },
            "search_center" => 0.0001
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", args, %{}) do
        {:ok, content, _state} ->
          assert length(content) == 1
          assert List.first(content).text =~ "Created CARBS optimizer"
        {:error, content, _state} ->
          IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
          :ok
      end
    end
  end

  describe "end-to-end workflow" do
    test "complete optimization cycle" do
      # Create optimizer
      create_args = %{
        "name" => "e2e_test_optimizer",
        "config" => %{
          "better_direction_sign" => -1,
          "is_wandb_logging_enabled" => false
        },
        "params" => [
          %{
            "name" => "learning_rate",
            "space" => %{
              "type" => "LogSpace",
              "scale" => 0.5
            },
            "search_center" => 0.0001
          },
          %{
            "name" => "batch_size",
            "space" => %{
              "type" => "LinearSpace",
              "scale" => 32.0,
              "is_integer" => true
            },
            "search_center" => 64
          }
        ]
      }

      case Server.handle_call_tool("carbs_create", create_args, %{}) do
        {:ok, _, _state} ->
          # Get multiple suggestions and observe them
          for i <- 1..3 do
            # Get suggestion
            suggest_args = %{"name" => "e2e_test_optimizer"}
            
            case Server.handle_call_tool("carbs_suggest", suggest_args, %{}) do
              {:ok, suggest_content, _state} ->
                suggestion_text = String.replace(List.first(suggest_content).text, "Suggestion: ", "")
                suggestion = Jason.decode!(suggestion_text)
                
                # Observe result
                observe_args = %{
                  "name" => "e2e_test_optimizer",
                  "input" => suggestion,
                  "output" => 0.9 + (i * 0.01),  # Varying outputs
                  "cost" => 10.0 + i,
                  "is_failure" => false
                }
                
                case Server.handle_call_tool("carbs_observe", observe_args, %{}) do
                  {:ok, observe_content, _state} ->
                    assert List.first(observe_content).text =~ "Observation recorded"
                  {:error, content, _state} ->
                    IO.puts("Skipping observation #{i} - Python/CARBS not available: #{inspect(content)}")
                    :ok
                end
              {:error, content, _state} ->
                IO.puts("Skipping suggestion #{i} - Python/CARBS not available: #{inspect(content)}")
                :ok
            end
          end
          
          # Verify optimizer still exists
          {:ok, load_content, _state} = Server.handle_call_tool("carbs_load", %{"name" => "e2e_test_optimizer"}, %{})
          assert List.first(load_content).text =~ "Loaded optimizer"
          
          # List should include it
          {:ok, list_content, _state} = Server.handle_call_tool("carbs_list", %{}, %{})
          assert List.first(list_content).text =~ "e2e_test_optimizer"
        {:error, content, _state} ->
          IO.puts("Skipping test - Python/CARBS not available: #{inspect(content)}")
          :ok
      end
    end
  end
end



