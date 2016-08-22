require "spec_helper"

describe IterationSterilizer do

  let(:jan4)  { Date.new(2016, 1, 4) }
  let(:jan7)  { Date.new(2016, 1, 7) }
  let(:jan10) { Date.new(2016, 1, 10) }
  let(:jan11) { Date.new(2016, 1, 11) }
  let(:jan13) { Date.new(2016, 1, 13) }
  let(:jan14) { Date.new(2016, 1, 14) }
  let(:jan17) { Date.new(2016, 1, 17) }
  let(:jan20) { Date.new(2016, 1, 20) }

  context "with an project with iterations that begin/end cleanly on its start and end date" do
    let(:project) { FactoryGirl.create(:project, start_date: jan4, end_date: jan10 )}

    it "returns the original set of iterations" do
      iterations = instance_double("iterations")
      sterilizer = described_class.new(project: project, iterations: iterations)
      allow(sterilizer).to receive(:partial_iterations?).and_return(false)

      result = sterilizer.sterilize

      expect(result).to eq(iterations)
    end
  end

  context "with an project with iterations that don't begin/end cleanly on its start and end dates" do
    let(:project) { FactoryGirl.create(:project, start_date: jan4, end_date: jan17) }

    let(:iteration_one) { Iteration.new(start_date: jan7, end_date: jan13, number: 1) }
    let(:iteration_two) { Iteration.new(start_date: jan14, end_date: jan20, number: 2)}
    let(:iterations)    { [iteration_one, iteration_two].collect.entries }

    subject(:sterilizer) { described_class.new(project: project, iterations: iterations) }

    it "creates a partial iteration for the unaccounted days before the first iteration's start date" do
      result = sterilizer.sterilize
      first_iteration = result.first

      expect(first_iteration.start_date).to eq(project.start_date)
      expect(first_iteration.end_date).to eq(iteration_one.start_date - 1)
    end

    it "creates a partial iteration for the unaccounted days after the last iteration's end date" do
      result = sterilizer.sterilize
      last_iteration = result.last

      expect(last_iteration.start_date).to eq(iteration_one.end_date   1)
      expect(last_iteration.end_date).to eq(project.end_date)
    end

    it "deletes an iteration if it goes beyond the end date of the project" do
      result = sterilizer.sterilize

      expect(result).not_to include(iteration_two)
    end
  end
end