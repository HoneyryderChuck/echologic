# Specification of a Proposal

# * Proposals can be either seen as Proposals or as Positions (/Standpoints) as which they are commonly refered to in concepts and ui
# * currently a Position expects only improvements as valid children, and only Questions as parents


class Proposal < StatementNode
  acts_as_draftable :tracked, :ready, :staged, :approved, :incorporated, :passed
  acts_as_alternative :Proposal
  has_children_of_types [:Improvement,true], [:Argument,true],[:BackgroundInfo,true]
  has_linkable_types :Proposal, :ProArgument, :ContraArgument

  # Overwriting the acts_as_taggable function saying this object is not taggable anymore
  def taggable?
    false
  end

  def self.taggable?
    false
  end

  #Overwriting of nested set function (hub's make it impossible to level them right)
  def level; 1; end
end
