from app.safety import safety_precheck

def test_gas_stops_immediately():
    risk = safety_precheck("Je sens une odeur de gaz dans la cuisine")
    assert risk.stop_diy is True
    assert risk.level.value == "emergency"

def test_water_near_power_stops():
    assert safety_precheck("Il y a de l'eau près d'une multiprise").stop_diy is True

def test_safe_text_continues():
    assert safety_precheck("Mon évier est un peu lent").stop_diy is False

def test_cigarette_alone_is_out_of_scope_not_emergency():
    risk = safety_precheck("Je montre une cigarette seule")
    assert risk.level.value == "out_of_scope"
    assert risk.stop_diy is False

def test_real_hazards_remain_stops():
    assert safety_precheck("fumée et flammes dans la cuisine").stop_diy is True
    assert safety_precheck("eau près d'une prise électrique").stop_diy is True
    assert safety_precheck("conducteur nu accessible").stop_diy is True
