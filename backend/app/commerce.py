from dataclasses import dataclass
from urllib.parse import quote_plus


@dataclass(frozen=True)
class CommerceSearchResult:
    provider: str
    mode: str
    query: str
    search_url: str
    availability_known: bool = False
    price_known: bool = False


def build_commerce_search(*, mode: str, item_type: str, generic_name: str,
                          purchase_search_query: str | None = None,
                          postal_code: str | None = None,
                          city: str | None = None) -> CommerceSearchResult:
    item = (purchase_search_query or generic_name).strip()[:180]
    area = " ".join(value.strip() for value in (postal_code, city) if value and value.strip())[:100]
    query = f"{item} magasin bricolage {area}".strip() if mode == "nearby" else item
    if mode == "nearby":
        url = "https://www.google.com/maps/search/?api=1&query=" + quote_plus(query)
        provider = "NEARBY_STORE"
    else:
        url = "https://www.google.com/search?q=" + quote_plus(query)
        provider = "EXTERNAL_SEARCH"
    return CommerceSearchResult(provider, mode, query, url)
