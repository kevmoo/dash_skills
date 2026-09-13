/// Concrete base: `sealed` implies `abstract`, so sealing would forbid
/// constructing it. Too large a change for this rule to suggest.
class Concrete {}

class ConcreteOne extends Concrete {}

class ConcreteTwo extends Concrete {}
