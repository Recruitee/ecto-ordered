defmodule EctoOrderedTest do
  use EctoOrdered.TestCase
  alias EctoOrderedTest.Repo
  import Ecto.Query

  defmodule Model do
    use Ecto.Model
    use EctoOrdered, repo: Repo

    schema "model" do
      field :title,            :string
      field :position,         :integer
    end
  end

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(EctoOrderedTest.Repo)
  end


  # No scope

  ## Inserting

  test "inserting item with no position" do
    for i <- 1..10 do
      model = %Model{title: "item with no position, going to be ##{i}"} |> Repo.insert!
      assert model.position == i
    end
    assert (from m in Model, select: m.position) |> Repo.all == Enum.into(1..10, [])
  end

  test "inserting item with a correct appending position" do
    %Model{title: "item with no position, going to be #1"} |> Repo.insert
    model = %Model{title: "item #2", position: 2} |> Repo.insert!
    assert model.position == 2
  end

  test "inserting item with a gapped position" do
    %Model{title: "item with no position, going to be #1"} |> Repo.insert
    assert_raise EctoOrdered.InvalidMove, "too large", fn ->
      %Model{title: "item #10", position: 10} |> Repo.insert
    end
  end

  test "inserting item with an inserting position" do
    model1 = %Model{title: "item with no position, going to be #1"} |> Repo.insert!
    model2 = %Model{title: "item with no position, going to be #2"} |> Repo.insert!
    model3 = %Model{title: "item with no position, going to be #3"} |> Repo.insert!
    model = %Model{title: "item #2", position: 2} |> Repo.insert!
    assert model.position == 2
    assert Repo.get(Model, model1.id).position == 1
    assert Repo.get(Model, model2.id).position == 3
    assert Repo.get(Model, model3.id).position == 4
  end

  test "inserting item with an inserting position at #1" do
    model1 = %Model{title: "item with no position, going to be #1"} |> Repo.insert!
    model2 = %Model{title: "item with no position, going to be #2"} |> Repo.insert!
    model3 = %Model{title: "item with no position, going to be #3"} |> Repo.insert!
    model = %Model{title: "item #1", position: 1} |> Repo.insert!
    assert model.position == 1
    assert Repo.get(Model, model1.id).position == 2
    assert Repo.get(Model, model2.id).position == 3
    assert Repo.get(Model, model3.id).position == 4
  end

  ## Moving

  test "updating item with the same position" do
    model = %Model{title: "item with no position"} |> Repo.insert!
    model1 = %Model{model | title: "item with a position"} |> Repo.update!
    assert model.position == model1.position
  end

  test "replacing an item below" do
    model1 = %Model{title: "item #1"} |> Repo.insert!
    model2 = %Model{title: "item #2"} |> Repo.insert!
    model3 = %Model{title: "item #3"} |> Repo.insert!
    model4 = %Model{title: "item #4"} |> Repo.insert!
    model5 = %Model{title: "item #5"} |> Repo.insert!

    model2 |> Model.move_position(4) |> Repo.update

    assert Repo.get(Model, model1.id).position == 1
    assert Repo.get(Model, model3.id).position == 2
    assert Repo.get(Model, model4.id).position == 3
    assert Repo.get(Model, model2.id).position == 4
    assert Repo.get(Model, model5.id).position == 5
  end

  test "replacing an item above" do
    model1 = %Model{title: "item #1"} |> Repo.insert!
    model2 = %Model{title: "item #2"} |> Repo.insert!
    model3 = %Model{title: "item #3"} |> Repo.insert!
    model4 = %Model{title: "item #4"} |> Repo.insert!
    model5 = %Model{title: "item #5"} |> Repo.insert!

    model4 |> Model.move_position(2) |> Repo.update

    assert Repo.get(Model, model1.id).position == 1
    assert Repo.get(Model, model4.id).position == 2
    assert Repo.get(Model, model2.id).position == 3
    assert Repo.get(Model, model3.id).position == 4
    assert Repo.get(Model, model5.id).position == 5
  end

  test "updating item with a tail position" do
    model1 = %Model{title: "item #1"} |> Repo.insert!
    model2 = %Model{title: "item #2"} |> Repo.insert!
    model3 = %Model{title: "item #3"} |> Repo.insert!

    model2 |> Model.move_position(4) |> Repo.update

    assert Repo.get(Model, model1.id).position == 1
    assert Repo.get(Model, model3.id).position == 2
    assert Repo.get(Model, model2.id).position == 3
  end

  ## Deletion

  test "deleting an item" do
    model1 = %Model{title: "item #1"} |> Repo.insert!
    model2 = %Model{title: "item #2"} |> Repo.insert!
    model3 = %Model{title: "item #3"} |> Repo.insert!
    model4 = %Model{title: "item #4"} |> Repo.insert!
    model5 = %Model{title: "item #5"} |> Repo.insert!

    model2 |> Repo.delete

    assert Repo.get(Model, model1.id).position == 1
    assert Repo.get(Model, model3.id).position == 2
    assert Repo.get(Model, model4.id).position == 3
    assert Repo.get(Model, model5.id).position == 4
  end

end


defmodule EctoOrderedTest.Scoped do
  use EctoOrdered.TestCase
  alias EctoOrderedTest.Repo
  import Ecto.Query

  defmodule Model do
    use Ecto.Model
    use EctoOrdered, field: :scoped_position, scope: :scope, repo: Repo

    schema "scoped_model" do
      field :title,            :string
      field :scope,            :integer
      field :scoped_position,  :integer
    end
  end

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(EctoOrderedTest.Repo)
  end
  # Insertion

  test "scoped: inserting item with no position" do
    for s <- 1..10, i <- 1..10 do
      model = %Model{scope: s, title: "item with no position, going to be ##{i}"} |> Repo.insert!
      assert model.scoped_position == i
    end
    for s <- 1..10 do
      assert (from m in Model, select: m.scoped_position, where: m.scope == ^s) |>
      Repo.all == Enum.into(1..10, [])
    end

  end

  test "scoped: inserting item with a correct appending position" do
    %Model{scope: 10, title: "item with no position, going to be #1"} |> Repo.insert
    %Model{scope: 11, title: "item #2"} |> Repo.insert

    model = %Model{scope: 10, title: "item #2", scoped_position: 2} |> Repo.insert!

    assert model.scoped_position == 2
  end

  test "scoped: inserting item with a gapped position" do
    %Model{scope: 1, title: "item with no position, going to be #1"} |> Repo.insert
    assert_raise EctoOrdered.InvalidMove, "too large", fn ->
      %Model{scope: 1, title: "item #10", scoped_position: 10} |> Repo.insert
    end
  end

  test "scoped: inserting item with an inserting position" do
    model1 = %Model{scope: 1, title: "item with no position, going to be #1"} |> Repo.insert!
    model2 = %Model{scope: 1, title: "item with no position, going to be #2"} |> Repo.insert!
    model3 = %Model{scope: 1, title: "item with no position, going to be #3"} |> Repo.insert!

    model = %Model{scope: 1,  title: "item #2", scoped_position: 2} |> Repo.insert!

    assert model.scoped_position == 2
    assert Repo.get(Model, model1.id).scoped_position == 1
    assert Repo.get(Model, model2.id).scoped_position == 3
    assert Repo.get(Model, model3.id).scoped_position == 4
  end

  test "scoped: inserting item with an inserting position at #1" do
    model1 = %Model{scope: 1, title: "item with no position, going to be #1"} |> Repo.insert!
    model2 = %Model{scope: 1, title: "item with no position, going to be #2"} |> Repo.insert!
    model3 = %Model{scope: 1, title: "item with no position, going to be #3"} |> Repo.insert!
    model = %Model{scope: 1, title: "item #1", scoped_position: 1} |> Repo.insert!
    assert model.scoped_position == 1
    assert Repo.get(Model, model1.id).scoped_position == 2
    assert Repo.get(Model, model2.id).scoped_position == 3
    assert Repo.get(Model, model3.id).scoped_position == 4
  end

  ## Moving

  test "scoped: updating item with the same position" do
    model = %Model{scope: 1, title: "item with no position"} |> Repo.insert!
    model1 = %Model{model | title: "item with a position", scope: 1} |> Repo.update!
    assert model.scoped_position == model1.scoped_position
  end

  test "scoped: replacing an item below" do
    model1 = %Model{scope: 1, title: "item #1"} |> Repo.insert!
    model2 = %Model{scope: 1, title: "item #2"} |> Repo.insert!
    model3 = %Model{scope: 1, title: "item #3"} |> Repo.insert!
    model4 = %Model{scope: 1, title: "item #4"} |> Repo.insert!
    model5 = %Model{scope: 1, title: "item #5"} |> Repo.insert!

    model2 |> Model.move_scoped_position(4) |> Repo.update

    assert Repo.get(Model, model1.id).scoped_position == 1
    assert Repo.get(Model, model3.id).scoped_position == 2
    assert Repo.get(Model, model4.id).scoped_position == 3
    assert Repo.get(Model, model2.id).scoped_position == 4
    assert Repo.get(Model, model5.id).scoped_position == 5
  end

  test "scoped: replacing an item above" do
    model1 = %Model{scope: 1, title: "item #1"} |> Repo.insert!
    model2 = %Model{scope: 1, title: "item #2"} |> Repo.insert!
    model3 = %Model{scope: 1, title: "item #3"} |> Repo.insert!
    model4 = %Model{scope: 1, title: "item #4"} |> Repo.insert!
    model5 = %Model{scope: 1, title: "item #5"} |> Repo.insert!

    model4 |> Model.move_scoped_position(2) |> Repo.update

    assert Repo.get(Model, model1.id).scoped_position == 1
    assert Repo.get(Model, model4.id).scoped_position == 2
    assert Repo.get(Model, model2.id).scoped_position == 3
    assert Repo.get(Model, model3.id).scoped_position == 4
    assert Repo.get(Model, model5.id).scoped_position == 5
  end

  test "scoped: updating item with a tail position" do
    model1 = %Model{scope: 1, title: "item #1"} |> Repo.insert!
    model2 = %Model{scope: 1, title: "item #2"} |> Repo.insert!
    model3 = %Model{scope: 1, title: "item #3"} |> Repo.insert!

    model2 |> Model.move_scoped_position(4) |> Repo.update

    assert Repo.get(Model, model1.id).scoped_position == 1
    assert Repo.get(Model, model3.id).scoped_position == 2
    assert Repo.get(Model, model2.id).scoped_position == 3
  end

  test "scoped: moving between scopes" do
    model1 = %Model{scope: 1, title: "item #1"} |> Repo.insert!
    model2 = %Model{scope: 1, title: "item #2"} |> Repo.insert!
    model3 = %Model{scope: 1, title: "item #3"} |> Repo.insert!

    xmodel1 = %Model{scope: 2, title: "item #1"} |> Repo.insert!
    xmodel2 = %Model{scope: 2, title: "item #2"} |> Repo.insert!
    xmodel3 = %Model{scope: 2, title: "item #3"} |> Repo.insert!

    model2 |> Model.move_scoped_position(4) |> Ecto.Changeset.put_change(:scope, 2) |> Repo.update

    assert Repo.get(Model, model1.id).scoped_position == 1
    assert Repo.get(Model, model1.id).scope == 1
    assert Repo.get(Model, model3.id).scoped_position == 2
    assert Repo.get(Model, model3.id).scope == 1

    assert Repo.get(Model, xmodel1.id).scoped_position == 1
    assert Repo.get(Model, xmodel2.id).scoped_position == 2
    assert Repo.get(Model, xmodel3.id).scoped_position == 3
    assert Repo.get(Model, model2.id).scoped_position == 4
    assert Repo.get(Model, model2.id).scope == 2
  end

  ## Deletion

  test "scoped: deleting an item" do
    model1 = %Model{title: "item #1", scope: 1} |> Repo.insert!
    model2 = %Model{title: "item #2", scope: 1} |> Repo.insert!
    model3 = %Model{title: "item #3", scope: 1} |> Repo.insert!
    model4 = %Model{title: "item #4", scope: 1} |> Repo.insert!
    model5 = %Model{title: "item #5", scope: 1} |> Repo.insert!

    model2 |> Repo.delete

    assert Repo.get(Model, model1.id).scoped_position == 1
    assert Repo.get(Model, model3.id).scoped_position == 2
    assert Repo.get(Model, model4.id).scoped_position == 3
    assert Repo.get(Model, model5.id).scoped_position == 4
  end
end
