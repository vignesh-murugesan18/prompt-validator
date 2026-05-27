class PromptDigestMailer < ApplicationMailer
  def digest_email(preference:, digest:)
    @preference = preference
    @digest = digest
    @session = preference.prompt_session

    mail(
      to: preference.email,
      subject: "#{digest.period_label} prompt coach digest · avg #{digest.overall_average}/10"
    )
  end

  def analysis_complete_email(preference:, prompt_analysis:)
    @preference = preference
    @prompt_analysis = prompt_analysis
    @session = preference.prompt_session

    mail(
      to: preference.email,
      subject: "Prompt analysis ready · #{prompt_analysis.score}/10"
    )
  end
end
