module Questions
  class RetirementIncomeController < QuestionsController
    layout "yes_no_question"

    def self.show?(intake)
      intake.had_social_security_or_retirement_yes?
    end

    private

    def method_name
      "had_retirement_income"
    end
  end
end
