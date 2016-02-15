#
# (c) 2014 -- onwards Georgios Gousios <gousiosg@gmail.com>
#
# BSD licensed, see LICENSE in top level dir
#
#
# Loads the contributors.csv file, renames columns to abbreviated names
# Stores results in the `contributors` workspace variable
#
source('R/cmdline.R')

require(plyr)
contributors <- read.csv(file.path(data.file.location, "contributors-enriched.csv"))

column.mappings <- c(
  "Which.of.the.following.best.describes.your.role." = "Q1",
  "Which.of.the.following.best.describes.your.role....Other..please.specify." = "Q1.other",
  "How.many.years.have.you.been.programming" = "Q2",
  "How.many.years.have.you.worked.on.projects.that.are.developed.in.a.geographically.distributed.manner." = "Q3",
  "How.many.years.have.you.been.working.in.Open.Source.projects" = "Q4",
  "You.work.for" = "Q5",
  "Which..open.source..project.repository.are.you.mainly.contributing.pull.requests.to..e.g..rails.rails...Please.specify.only.one.and.answer.the.remaining.questions.with.this.repository.in.mind....Open.Ended.Response" = "Q6",
  "Why.do.you.contribute.to.this.specific.repository....It.is.my.day.time.job" = "Q7.A1",
  "Why.do.you.contribute.to.this.specific.repository....I.use.this.project.as.part.my.own.projects" = "Q7.A2",
  "Why.do.you.contribute.to.this.specific.repository....I.am.personally.interested.in.the.technology.being.developed" = "Q7.A3",
  "Why.do.you.contribute.to.this.specific.repository....Coding.for.this.project.is.intellectually.stimulating" = "Q7.A4",
  "Why.do.you.contribute.to.this.specific.repository....I.contribute.to.this.project.to.sharpen.my.programming.skills" = "Q7.A5",
  "Why.do.you.contribute.to.this.specific.repository....I.contribute.to.this.project.to.enrich.my.Github.profile.CV" = "Q7.A6",
  "Why.do.you.contribute.to.this.specific.repository....I.like.to.devote.my.free.time.to.a.good.cause" = "Q7.A7",
  "Why.do.you.contribute.to.this.specific.repository....Other..please.specify." = "Q7.other",
  "How.many.pull.requests.did.you.submit.to.this.repo.in.the.last.month." = "Q8",
  "How.do.you.contribute.code.to.the.project....I.have.commit.access.and.commit..to.the.main.branch" = "Q9.A1",
  "How.do.you.contribute.code.to.the.project....I.have.commit.access.and.commit.to.other.branches" = "Q9.A2",
  "How.do.you.contribute.code.to.the.project....I.have.commit.access.and.contribute.through.branch.to.branch.pull.requests" = "Q9.A3",
  "How.do.you.contribute.code.to.the.project....I.only.contribute.to.the.project.through.pull.requests" = "Q9.A4",
  "How.do.you.contribute.code.to.the.project....Other..please.specify." = "Q9.other",
  "I.contribute.pull.requests.containing.exclusively...Source.code" = "Q10.A1",
  "I.contribute.pull.requests.containing.exclusively...Test.code" = "Q10.A2 ",
  "I.contribute.pull.requests.containing.exclusively...Documentation" = "Q10.A3",
  "I.contribute.pull.requests.containing.exclusively...Source.code...Test.code" = "Q10.A4",
  "I.contribute.pull.requests.containing.exclusively...Source.code...Documentation" = "Q10.A5",
  "I.contribute.pull.requests.containing.exclusively...Test.code...Documentation" = "Q10.A6",
  "I.contribute.pull.requests.containing.exclusively...Source.Code..Test.code.and.Documentation" = "Q10.A7",
  "Before.starting.to.work.on.a.pull.request..I...Communicate.my.changes.to.the.project.core.team" = "Q11.A1",
  "Before.starting.to.work.on.a.pull.request..I...Lookup.project.pull.request.guidelines" = "Q11.A2",
  "Before.starting.to.work.on.a.pull.request..I...Lookup.for.open.issues.related.to.my.changes" = "Q11.A3",
  "Before.starting.to.work.on.a.pull.request..I...Check.whether.similar.pull.requests.were.processed.recently" = "Q11.A4",
  "Before.starting.to.work.on.a.pull.request..I...Check.other.project.branches..or.forks..for.related.features" = "Q11.A5",
  "Before.starting.to.work.on.a.pull.request..I...Check.project.discussions..emails.forums.IRC..for.related.topics" = "Q11.A7",
  "Before.starting.to.work.on.a.pull.request..I...Get.assigned.some.work.by.my.project.leader" = "Q11.A8",
  "Before.starting.to.work.on.a.pull.request..I...Other..please.specify." = "Q11.other",
  "How.do.you.communicate.the.intended.changes.with.the.project.s.core.team.....Email" = "Q12.A1",
  "How.do.you.communicate.the.intended.changes.with.the.project.s.core.team.....Issue.tracking..I.open.an.issue.describing.the.problem.and.the.potential.fix" = "Q12.A2",
  "How.do.you.communicate.the.intended.changes.with.the.project.s.core.team.....Pull.request..I.open.a.minimal.pull.request.describing.the.problem.and.the.potential.fix" = "Q12.A3",
  "How.do.you.communicate.the.intended.changes.with.the.project.s.core.team.....IRC" = "Q12.A4",
  "How.do.you.communicate.the.intended.changes.with.the.project.s.core.team.....Twitter" = "Q12.A5",
  "How.do.you.communicate.the.intended.changes.with.the.project.s.core.team.....Skype.Hangouts.Other.form.of.synchronous.communication" = "Q12.A6",
  "How.do.you.communicate.the.intended.changes.with.the.project.s.core.team.....Face.to.face" = "Q12.A7",
  "How.do.you.communicate.the.intended.changes.with.the.project.s.core.team.....I.do.not.communicate.my.intended.changes" = "Q12.A8",
  "How.do.you.communicate.the.intended.changes.with.the.project.s.core.team.....Other..please.specify." = "Q12.other",
  "Did.you.look.up.for.the.project.s.pull.request.guidelines.at.least.once." = "Q13",
  "How.do.you.decide.on.the.contents.of.a.pull.request." = "Q14",
  "How.do.you.decide.on.the.contents.of.a.pull.request....Other..please.specify." = "Q14.other",
  "How.do.you.assess.the.quality.of.your.pull.request.before.submitting.it....Open.Ended.Response" = "Q15",
  "When.I.am.ready.to.submit.a.pull.request..I...Format.it.according.to.project.guidelines" = "Q16.A1",
  "When.I.am.ready.to.submit.a.pull.request..I...Run.the.tests.against.it" = "Q16.A2",
  "When.I.am.ready.to.submit.a.pull.request..I...Check.whether.similar.pull.requests.were.processed.recently" = "Q16.A3",
  "When.I.am.ready.to.submit.a.pull.request..I...Check.other.project.branches..or.forks..for.features.related.to.my.pull.request" = "Q16.A4",
  "When.I.am.ready.to.submit.a.pull.request..I...Check.project.discussions.for.topics.related.to.it" = "Q16.A5",
  "When.I.am.ready.to.submit.a.pull.request..I...Other..please.specify." = "Q16.other",
  "X.From.hereon..questions.are.not.project.specific..How.do.the.following.factors.affect.your.decision.to.contribute.to.a.project....Existence.of.project.roadmap" = "Q17.A1",
  "X.From.hereon..questions.are.not.project.specific..How.do.the.following.factors.affect.your.decision.to.contribute.to.a.project....Existence.of.contributor.guidelines" = "Q17.A2",
  "X.From.hereon..questions.are.not.project.specific..How.do.the.following.factors.affect.your.decision.to.contribute.to.a.project....Existence.of.issue.tracking.system" = "Q17.A3",
  "X.From.hereon..questions.are.not.project.specific..How.do.the.following.factors.affect.your.decision.to.contribute.to.a.project....Existence.of.code.review.process" = "Q17.A4",
  "X.From.hereon..questions.are.not.project.specific..How.do.the.following.factors.affect.your.decision.to.contribute.to.a.project....Large.numbers.of.already.open.pull.requests" = "Q17.A5",
  "X.From.hereon..questions.are.not.project.specific..How.do.the.following.factors.affect.your.decision.to.contribute.to.a.project....Project.is.famous" = "Q17.A6",
  "X.From.hereon..questions.are.not.project.specific..How.do.the.following.factors.affect.your.decision.to.contribute.to.a.project....Project.is.very.active" = "Q17.A7",
  "What.could.projects.do.to.reduce.barriers.for.new.contributors....Open.Ended.Response" = "Q18",
  "What.is.the.biggest.challenge..if.any..you.face.when.contributing.with.pull.requests....Open.Ended.Response" = "Q19",
  "What.kind.of.tools.would.you.expect.research.to.provide.you.with.in.order.to.assist.you.with.contributing.pull.requests....Open.Ended.Response" = "Q20",
  "Your.Github.login..This.will.allow.us.to.cross.check.your.replies.with.our.dataset..This.will.not.be.part.of.the.publicly.released.dataset....Open.Ended.Response" = "githubid",
  "Would.you.like.to.be.notified.when.the.questionnaire.results.have.been.processed..If.yes..please.fill.in.your.email.below....Open.Ended.Response" = "email"
)

contributors <- rename(contributors, column.mappings)

