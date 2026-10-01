import re
from .schemas import Analysis, ActionType, Risk, RiskLevel, NextAction, Diy

STOP_PATTERNS = {
    "gas": (r"odeur de gaz|fuite de gaz|gaz", RiskLevel.emergency),
    "fire": (r"fumée|flamme|incendie|brûle|brûlure", RiskLevel.emergency),
    "electric_exposure": (r"fil nu|conducteur nu|fils exposés|tableau ouvert|prise noircie|choc électrique|électri", RiskLevel.high),
    "water_electric": (r"eau.*prise|prise.*eau|multiprise.*eau", RiskLevel.high),
    "chemical": (r"mélang(er|e)|chlore.*acide|acide.*chlore|produit corrosif", RiskLevel.high),
    "pressure": (r"sous pression|condensateur|haute tension", RiskLevel.high),
    "structural": (r"fissure.*structure|plafond.*déforme|effondrement", RiskLevel.high),
    "major_leak": (r"fuite massive|incontrôlable|débordement", RiskLevel.high),
}
OUT_OF_SCOPE_PATTERNS = (r"\bcigarette\b", r"\bchaussure\b", r"\bchien\b", r"\bassiette\b", r"\bvisage\b", r"\bpaysage\b")

def safety_precheck(text: str) -> Risk:
    lowered = text.lower()
    flags = [name for name, (pattern, _) in STOP_PATTERNS.items() if re.search(pattern, lowered)]
    if not flags:
        if any(re.search(pattern, lowered) for pattern in OUT_OF_SCOPE_PATTERNS):
            return Risk(level=RiskLevel.out_of_scope, flags=["out_of_scope"], stop_diy=False)
        return Risk(level=RiskLevel.low, flags=[], stop_diy=False)
    level = RiskLevel.emergency if any(STOP_PATTERNS[f][1] == RiskLevel.emergency for f in flags) else RiskLevel.high
    return Risk(level=level, flags=flags, stop_diy=True)

def apply_postcheck(analysis: Analysis, source_text: str) -> Analysis:
    risk = safety_precheck(source_text)
    if risk.stop_diy or analysis.risk.stop_diy:
        analysis.risk = Risk(level=risk.level if risk.stop_diy else analysis.risk.level, flags=sorted(set(risk.flags + analysis.risk.flags)), stop_diy=True)
        analysis.diy = Diy(allowed=False, difficulty="stop")
        analysis.next_action = NextAction(type=ActionType.safety_stop, instruction="Ne poursuivez pas la réparation. Éloignez-vous du danger si vous pouvez le faire sans risque et contactez le service compétent.")
        analysis.assistant_message = "Cette situation peut être dangereuse. Je ne vais pas vous guider dans une réparation. Mettez-vous en sécurité et contactez un professionnel ou le service d'urgence adapté."
    elif risk.level == RiskLevel.out_of_scope or any(term in str(analysis.model_dump()).lower() for term in ("cigarette", "chaussure", "chien", "assiette", "paysage")):
        analysis.category = "out_of_scope"
        analysis.risk = Risk(level=RiskLevel.out_of_scope, flags=["out_of_scope"], stop_diy=False)
        analysis.diy = Diy(allowed=False, difficulty="clarify")
        analysis.next_action = NextAction(type=ActionType.ask_question, instruction="Je ne reconnais pas ici un problème domestique exploitable. Montrez-moi une zone de la maison ou expliquez ce qui vous inquiète.")
        analysis.assistant_message = "Je ne reconnais pas ici un problème domestique. Vous pouvez montrer une zone de la maison ou préciser votre question."
    return analysis
