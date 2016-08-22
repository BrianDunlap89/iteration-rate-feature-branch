describe IterationReport do

  let(:jan4)  { Date.new(2016, 1, 4) }
  let(:jan6)  { Date.new(2016, 1, 6) }
  let(:jan10) { Date.new(2016, 1, 10) }
  let(:jan11) { Date.new(2016, 1, 11) }
  let(:jan12) { Date.new(2016, 1, 12) }
  let(:jan17) { Date.new(2016, 1, 17) }
  let(:jan18) { Date.new(2016, 1, 18) }
  let(:jan24) { Date.new(2016, 1, 24) }

  context 'with an unchanging iteration rate' do
    context 'with a week long project' do
      let(:one_week_project) { FactoryGirl.create(:project, start_date: jan4, end_date: jan10) }
      let!(:iteration_rate)  { FactoryGirl.create(:iteration_rate, rate: 1, effective_date: jan4, project: one_week_project) }

      subject(:report) { described_class.new(project: one_week_project) }

      context 'with one week-long result' do
        let!(:week_long_result) { FactoryGirl.create(:result, start_date: jan4, end_date: jan10, project: one_week_project) }

        it 'should report the billable days of the result' do
          expect(report.total_billable_days_by_iteration).to eq([week_long_result.strength_adjusted_billable_days])
        end
      end
    end

      context 'with a result that is a subset of an iteration' do
        let!(:subset_result) { FactoryGirl.create(:result, start_date: jan4, end_date: jan6, project: one_week_project) }

        it 'should report the billable days of the result' do
          expect(report.total_billable_days_by_iteration).to eq([subset_result.strength_adjusted_billable_days])
        end
      end
    end
  end


    context 'a two-week-long project' do
      let(:two_week_project) { FactoryGirl.create(:project, start_date: jan4, end_date: jan17) }
      let!(:iteration_rate)  { FactoryGirl.create(:iteration_rate, rate: 1, effective_date: jan4, project: two_week_project) }

      subject(:report) { described_class.new(project: two_week_project) }


      context 'with three results' do
        let!(:result_one) { FactoryGirl.create(:result, start_date: jan4, end_date: jan10, project: two_week_project) }
        let!(:result_two)   { FactoryGirl.create(:result, start_date: jan11, end_date: jan17, project: two_week_project) }
        let!(:result_three) { FactoryGirl.create(:result, start_date: jan11, end_date: jan17, project: two_week_project) }

          it 'should report billable days of results by iteration' do
            expect(report.total_billable_days_by_iteration).to eq(
              [
               result_one.strength_adjusted_billable_days,
               result_two.strength_adjusted_billable_days + result_three.strength_adjusted_billable_days
              ]
            )
          end
        end

      context 'with a result that overlaps two iterations' do
      let!(:result)        { FactoryGirl.create(:result, start_date: jan6, end_date: jan12, project: two_week_project) }
      let!(:iteration_one) { Iteration.new(start_date: jan4, end_date: jan10) }
      let!(:iteration_two) { Iteration.new(start_date: jan11, end_date: jan17) }

        it 'correctly splits the billable days of the result by iteration' do
          expect(report.total_billable_days_by_iteration).to eq(
            [
              result.iteration_adjusted_billable_days(iteration_one),
              result.iteration_adjusted_billable_days(iteration_two)
            ]
          )
        end

      context 'with results with variable strength percentages' do
        let!(:quarter_strength_result) { FactoryGirl.create(:result, start_date: jan6, end_date: jan12, project: two_week_project, strength: 25) }

          it 'correctly applies the strength adjustment' do
            expect(report.total_billable_days_by_iteration).to eq(
              [
                result.iteration_adjusted_billable_days(iteration_one) + quarter_strength_result.iteration_adjusted_billable_days(iteration_one),
                result.iteration_adjusted_billable_days(iteration_two) + quarter_strength_result.iteration_adjusted_billable_days(iteration_two)
              ]
            )
          end
        end
      end
    end

    context 'with iterations that start mid-week' do
      let(:mid_iteration_project) { FactoryGirl.create(:project, start_date: jan4, end_date: jan17) }
      let!(:result_two)           { FactoryGirl.create(:result, start_date: jan11, end_date: jan17, project: mid_iteration_project) }

      let(:first_iteration)  { partial_iteration_report.iterations[0] }
      let(:middle_iteration) { partial_iteration_report.iterations[1] }
      let(:last_iteration)   { partial_iteration_report.iterations[-1] }

      let(:billable_days_by_iteration) { partial_iteration_report.total_billable_days_by_iteration }


        it 'generates the billable days of the first partial iteration' do
          first_iteration_billable_days = billable_days_by_iteration[0]

          expect(first_iteration_billable_days).to eq(result_one.iteration_adjusted_billable_days(first_iteration))
        end

        it 'generates the billable days of the last partial iteration' do
          last_iteration_billable_days = billable_days_by_iteration[-1]

          expect(last_iteration_billable_days).to eq(result_two.iteration_adjusted_billable_days(last_iteration))
        end


        it 'correctly generates the billable days of full iterations' do
          full_iteration_billable_days = billable_days_by_iteration[1]

          expect(full_iteration_billable_days).to eq(
          result_one.iteration_adjusted_billable_days(middle_iteration) + result_two.iteration_adjusted_billable_days(middle_iteration)
          )
        end
      end
    end
  end


  context 'with a project that has a changing iteration rate' do
    let(:project)  { FactoryGirl.create(:project, start_date: jan4, end_date: jan24) }

    let!(:result_one)   { FactoryGirl.create(:result, start_date: jan4, end_date: jan10, project: project) }
    let!(:result_two)   { FactoryGirl.create(:result, start_date: jan11, end_date: jan17, project: project) }
    let!(:result_three) { FactoryGirl.create(:result, start_date: jan18, end_date: jan24, project: project) }

    let!(:first_iteration_rate)  { FactoryGirl.create(:iteration_rate, rate: 1, effective_date: jan4, project: project) }
    let!(:second_iteration_rate) { FactoryGirl.create(:iteration_rate, rate: 2, effective_date: jan11, project: project) }

    let(:one_week_iteration) { Iteration.new(start_date: jan4, length: 7, end_date: jan10) }
    let(:two_week_iteration) { Iteration.new(start_date: jan11, length: 14, end_date: jan24) }

    subject(:report) { described_class.new(project: project) }

     it 'correctly reports billable days when a project timeline has variable iteration rates' do
       expect(report.total_billable_days_by_iteration).to eq(
         [
           result_one.iteration_adjusted_billable_days(one_week_iteration),
           result_two.iteration_adjusted_billable_days(two_week_iteration) + result_three.iteration_adjusted_billable_days(two_week_iteration)
         ]
       )
     end
   end
 end