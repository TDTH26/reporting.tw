"""Structured interview: server-defined, versioned, pre-translated questions with branching.

Clients render whatever this module serves (GET /v1/public/interview), so questions can change
without an app release. Answers are validated here and mapped to craft domain / type and to
severity-relevant facts. Free text stays in the report's `description`.
"""

from dataclasses import dataclass, field

VERSION = "1"
L = ("zh-TW", "en", "vi", "id", "th", "fil", "de", "fr")

# German / French, keyed by the English text (shared labels like "Not sure" translate once).
DE_FR = {
    "Where is it?": ("Wo befindet es sich?", "Où se trouve-t-il ?"),
    "In the air": ("In der Luft", "Dans les airs"),
    "On the water": ("Auf dem Wasser", "Sur l'eau"),
    "Under water (periscope, mast or odd wake)": (
        "Unter Wasser (Periskop, Mast oder seltsames Kielwasser)",
        "Sous l'eau (périscope, mât ou sillage inhabituel)",
    ),
    "On the shore or beach": ("Am Ufer oder Strand", "Sur le rivage ou la plage"),
    "What does it look like?": ("Wie sieht es aus?", "À quoi ressemble-t-il ?"),
    "Multirotor (quadcopter etc.)": ("Multikopter (Quadrocopter usw.)", "Multirotor (quadricoptère, etc.)"),
    "Fixed wing (like a small plane)": ("Starrflügler (wie ein kleines Flugzeug)", "Aile fixe (comme un petit avion)"),
    "Balloon or airship": ("Ballon oder Luftschiff", "Ballon ou dirigeable"),
    "Not sure": ("Nicht sicher", "Je ne sais pas"),
    "Any lights?": ("Sind Lichter zu sehen?", "Y a-t-il des lumières ?"),
    "None": ("Keine", "Aucune"),
    "Steady": ("Dauerlicht", "Fixes"),
    "Flashing": ("Blinkend", "Clignotantes"),
    "What kind of craft?": ("Was für ein Boot oder Schiff?", "Quel type d'embarcation ?"),
    "Small boat with nobody on board": ("Kleines Boot ohne Personen an Bord", "Petit bateau sans personne à bord"),
    "Speedboat or rubber boat": ("Schnellboot oder Schlauchboot", "Vedette rapide ou bateau pneumatique"),
    "Fishing boat": ("Fischerboot", "Bateau de pêche"),
    "Large ship": ("Großes Schiff", "Grand navire"),
    "Can you see people on board?": ("Sehen Sie Personen an Bord?", "Voyez-vous des personnes à bord ?"),
    "Yes": ("Ja", "Oui"),
    "No": ("Nein", "Non"),
    "Can't tell": ("Nicht erkennbar", "Impossible à dire"),
    "About how long?": ("Ungefähr wie lang?", "Quelle longueur environ ?"),
    "Under 5 m": ("Unter 5 m", "Moins de 5 m"),
    "5–20 m": ("5–20 m", "5–20 m"),
    "Over 20 m": ("Über 20 m", "Plus de 20 m"),
    "Which way is it moving?": ("In welche Richtung bewegt es sich?", "Dans quelle direction se déplace-t-il ?"),
    "Towards the shore": ("Auf das Ufer zu", "Vers le rivage"),
    "Along the coast": ("Entlang der Küste", "Le long de la côte"),
    "Away from the shore": ("Vom Ufer weg", "En s'éloignant du rivage"),
    "Not moving": ("Bewegt sich nicht", "Immobile"),
    "About how far from the shore?": ("Ungefähr wie weit vom Ufer?", "À quelle distance du rivage environ ?"),
    "Within 500 m": ("Innerhalb von 500 m", "À moins de 500 m"),
    "0.5–2 km": ("0,5–2 km", "0,5–2 km"),
    "More than 2 km": ("Mehr als 2 km", "Plus de 2 km"),
    "What did you see?": ("Was haben Sie gesehen?", "Qu'avez-vous vu ?"),
    "Periscope or mast": ("Periskop oder Mast", "Périscope ou mât"),
    "A wake with no boat": ("Kielwasser ohne Boot", "Un sillage sans bateau"),
    "Something surfacing": ("Etwas taucht auf", "Quelque chose fait surface"),
    "A boat landed or beached": ("Ein Boot ist gelandet oder gestrandet", "Un bateau a accosté ou s'est échoué"),
    "An unknown object washed ashore": (
        "Ein unbekannter Gegenstand wurde angespült",
        "Un objet inconnu rejeté sur le rivage",
    ),
    "People unloading things": ("Personen laden etwas aus", "Des personnes déchargent des objets"),
    "How many?": ("Wie viele?", "Combien ?"),
    "1": ("1", "1"),
    "2": ("2", "2"),
    "3 or more": ("3 oder mehr", "3 ou plus"),
}


def t(zh, en, vi, id_, th, fil) -> dict[str, str]:
    de, fr = DE_FR[en]
    return dict(zip(L, (zh, en, vi, id_, th, fil, de, fr), strict=True))


# Each question: id, label, options (value -> label), optional `when` {question_id: [values]}.
QUESTIONS: list[dict] = [
    {
        "id": "domain",
        "label": t(
            "可疑物體在哪裡？", "Where is it?", "Vật thể ở đâu?", "Di mana objeknya?", "วัตถุอยู่ที่ไหน?", "Nasaan ito?"
        ),
        "options": {
            "aerial": t("在空中", "In the air", "Trên không", "Di udara", "บนฟ้า", "Nasa himpapawid"),
            "surface": t(
                "在水面上", "On the water", "Trên mặt nước", "Di permukaan air", "บนผิวน้ำ", "Nasa ibabaw ng tubig"
            ),
            "subsurface": t(
                "在水面下（潛望鏡、桅杆或不明尾流）",
                "Under water (periscope, mast or odd wake)",
                "Dưới nước (kính tiềm vọng, cột hoặc vệt nước lạ)",
                "Di bawah air (periskop, tiang atau jejak air aneh)",
                "ใต้น้ำ (กล้องตาเรือ เสา หรือรอยคลื่นแปลก)",
                "Nasa ilalim ng tubig (periskopyo, palo o kakaibang alon)",
            ),
            "shore": t(
                "在岸邊或沙灘上",
                "On the shore or beach",
                "Trên bờ hoặc bãi biển",
                "Di pantai atau tepi",
                "บนชายฝั่งหรือชายหาด",
                "Nasa dalampasigan o baybayin",
            ),
        },
    },
    # --- aerial
    {
        "id": "aerial_type",
        "when": {"domain": ["aerial"]},
        "label": t(
            "看起來像什麼？",
            "What does it look like?",
            "Nó trông như thế nào?",
            "Seperti apa bentuknya?",
            "มีลักษณะอย่างไร?",
            "Ano ang hitsura nito?",
        ),
        "options": {
            "multirotor": t(
                "多旋翼（四軸等）",
                "Multirotor (quadcopter etc.)",
                "Nhiều cánh quạt (4 cánh…)",
                "Multirotor (quadcopter dll.)",
                "หลายใบพัด (โดรน 4 ใบพัด ฯลฯ)",
                "Multirotor (quadcopter atbp.)",
            ),
            "fixed_wing": t(
                "固定翼（像小飛機）",
                "Fixed wing (like a small plane)",
                "Cánh cố định (như máy bay nhỏ)",
                "Sayap tetap (seperti pesawat kecil)",
                "ปีกตรึง (เหมือนเครื่องบินเล็ก)",
                "Fixed wing (parang maliit na eroplano)",
            ),
            "balloon": t(
                "氣球或飛艇",
                "Balloon or airship",
                "Khinh khí cầu hoặc khí cầu",
                "Balon atau kapal udara",
                "บอลลูนหรือเรือเหาะ",
                "Lobo o airship",
            ),
            "unsure": t("不確定", "Not sure", "Không chắc", "Tidak yakin", "ไม่แน่ใจ", "Hindi sigurado"),
        },
    },
    {
        "id": "aerial_lights",
        "when": {"domain": ["aerial"]},
        "label": t("有燈光嗎？", "Any lights?", "Có đèn không?", "Ada lampu?", "มีไฟไหม?", "May ilaw ba?"),
        "options": {
            "none": t("沒有", "None", "Không", "Tidak ada", "ไม่มี", "Wala"),
            "steady": t("恆亮", "Steady", "Sáng liên tục", "Menyala terus", "ไฟติดค้าง", "Tuloy-tuloy"),
            "flashing": t("閃爍", "Flashing", "Nhấp nháy", "Berkedip", "กะพริบ", "Kumikislap"),
            "unsure": t("不確定", "Not sure", "Không chắc", "Tidak yakin", "ไม่แน่ใจ", "Hindi sigurado"),
        },
    },
    # --- surface
    {
        "id": "surface_type",
        "when": {"domain": ["surface"]},
        "label": t(
            "是什麼樣的船？",
            "What kind of craft?",
            "Loại phương tiện gì?",
            "Jenis kapal apa?",
            "เป็นเรือแบบไหน?",
            "Anong uri ng sasakyang-dagat?",
        ),
        "options": {
            "unmanned": t(
                "無人小艇（看不到人）",
                "Small boat with nobody on board",
                "Thuyền nhỏ không người",
                "Perahu kecil tanpa awak",
                "เรือเล็กไม่มีคน",
                "Maliit na bangkang walang tao",
            ),
            "speedboat": t(
                "快艇或橡皮艇",
                "Speedboat or rubber boat",
                "Xuồng cao tốc hoặc xuồng cao su",
                "Speedboat atau perahu karet",
                "เรือเร็วหรือเรือยาง",
                "Speedboat o rubber boat",
            ),
            "fishing": t("漁船", "Fishing boat", "Tàu cá", "Kapal nelayan", "เรือประมง", "Bangkang pangisda"),
            "ship": t("大型船舶", "Large ship", "Tàu lớn", "Kapal besar", "เรือขนาดใหญ่", "Malaking barko"),
            "unsure": t("不確定", "Not sure", "Không chắc", "Tidak yakin", "ไม่แน่ใจ", "Hindi sigurado"),
        },
    },
    {
        "id": "surface_crew",
        "when": {"domain": ["surface"]},
        "label": t(
            "船上看得到人嗎？",
            "Can you see people on board?",
            "Có thấy người trên đó không?",
            "Apakah terlihat orang di atasnya?",
            "เห็นคนบนเรือไหม?",
            "May nakikita bang tao sa loob?",
        ),
        "options": {
            "yes": t("看得到", "Yes", "Có", "Ya", "เห็น", "Oo"),
            "no": t("看不到", "No", "Không", "Tidak", "ไม่เห็น", "Wala"),
            "unsure": t("無法判斷", "Can't tell", "Không rõ", "Tidak bisa dipastikan", "บอกไม่ได้", "Hindi masabi"),
        },
    },
    {
        "id": "surface_size",
        "when": {"domain": ["surface", "shore"]},
        "label": t(
            "大約多長？",
            "About how long?",
            "Dài khoảng bao nhiêu?",
            "Kira-kira berapa panjang?",
            "ยาวประมาณเท่าไร?",
            "Mga gaano kahaba?",
        ),
        "options": {
            "lt5": t("5 公尺以下", "Under 5 m", "Dưới 5 m", "Kurang dari 5 m", "ไม่ถึง 5 ม.", "Wala pang 5 m"),
            "5to20": t("5–20 公尺", "5–20 m", "5–20 m", "5–20 m", "5–20 ม.", "5–20 m"),
            "gt20": t("20 公尺以上", "Over 20 m", "Trên 20 m", "Lebih dari 20 m", "เกิน 20 ม.", "Higit 20 m"),
            "unsure": t("不確定", "Not sure", "Không chắc", "Tidak yakin", "ไม่แน่ใจ", "Hindi sigurado"),
        },
    },
    {
        "id": "surface_heading",
        "when": {"domain": ["surface", "subsurface"]},
        "label": t(
            "移動方向？",
            "Which way is it moving?",
            "Đang di chuyển hướng nào?",
            "Bergerak ke arah mana?",
            "กำลังเคลื่อนที่ไปทางไหน?",
            "Saan ito papunta?",
        ),
        "options": {
            "towards_shore": t(
                "朝岸邊靠近", "Towards the shore", "Về phía bờ", "Menuju pantai", "เข้าหาฝั่ง", "Papunta sa dalampasigan"
            ),
            "along_coast": t(
                "沿著海岸", "Along the coast", "Dọc bờ biển", "Menyusuri pantai", "เลียบชายฝั่ง", "Paikot sa baybayin"
            ),
            "away": t(
                "遠離岸邊",
                "Away from the shore",
                "Ra xa bờ",
                "Menjauhi pantai",
                "ออกห่างจากฝั่ง",
                "Palayo sa dalampasigan",
            ),
            "stationary": t("停著不動", "Not moving", "Đứng yên", "Diam", "อยู่กับที่", "Hindi gumagalaw"),
        },
    },
    {
        "id": "distance_offshore",
        "when": {"domain": ["surface", "subsurface"]},
        "label": t(
            "離岸大約多遠？",
            "About how far from the shore?",
            "Cách bờ khoảng bao xa?",
            "Kira-kira seberapa jauh dari pantai?",
            "ห่างจากฝั่งประมาณเท่าไร?",
            "Mga gaano kalayo sa dalampasigan?",
        ),
        "options": {
            "lt500": t("500 公尺內", "Within 500 m", "Trong 500 m", "Dalam 500 m", "ภายใน 500 ม.", "Sa loob ng 500 m"),
            "500to2000": t("0.5–2 公里", "0.5–2 km", "0,5–2 km", "0,5–2 km", "0.5–2 กม.", "0.5–2 km"),
            "gt2000": t("2 公里以上", "More than 2 km", "Hơn 2 km", "Lebih dari 2 km", "เกิน 2 กม.", "Higit 2 km"),
        },
    },
    # --- subsurface
    {
        "id": "subsurface_seen",
        "when": {"domain": ["subsurface"]},
        "label": t(
            "看到什麼？",
            "What did you see?",
            "Bạn đã thấy gì?",
            "Apa yang Anda lihat?",
            "เห็นอะไร?",
            "Ano ang nakita mo?",
        ),
        "options": {
            "periscope": t(
                "潛望鏡或桅杆",
                "Periscope or mast",
                "Kính tiềm vọng hoặc cột",
                "Periskop atau tiang",
                "กล้องตาเรือหรือเสา",
                "Periskopyo o palo",
            ),
            "wake": t(
                "沒有船卻有尾流",
                "A wake with no boat",
                "Vệt nước nhưng không có thuyền",
                "Jejak air tanpa kapal",
                "รอยคลื่นแต่ไม่เห็นเรือ",
                "Alon na walang bangka",
            ),
            "surfacing": t(
                "物體浮出水面",
                "Something surfacing",
                "Vật gì đó nổi lên",
                "Sesuatu muncul ke permukaan",
                "มีวัตถุโผล่ขึ้นมา",
                "May lumilitaw sa tubig",
            ),
        },
    },
    # --- shore
    {
        "id": "shore_seen",
        "when": {"domain": ["shore"]},
        "label": t(
            "看到什麼？",
            "What did you see?",
            "Bạn đã thấy gì?",
            "Apa yang Anda lihat?",
            "เห็นอะไร?",
            "Ano ang nakita mo?",
        ),
        "options": {
            "boat_landed": t(
                "船隻靠岸或擱淺",
                "A boat landed or beached",
                "Thuyền cập bờ hoặc mắc cạn",
                "Perahu mendarat atau terdampar",
                "เรือขึ้นฝั่งหรือเกยตื้น",
                "Bangkang dumaong o sumadsad",
            ),
            "object_ashore": t(
                "不明物體被沖上岸",
                "An unknown object washed ashore",
                "Vật lạ dạt vào bờ",
                "Benda tak dikenal terdampar",
                "วัตถุแปลกถูกซัดขึ้นฝั่ง",
                "Hindi kilalang bagay na inanod",
            ),
            "people_unloading": t(
                "有人在搬運物品上岸",
                "People unloading things",
                "Có người đang dỡ hàng lên bờ",
                "Orang menurunkan barang",
                "มีคนขนของขึ้นฝั่ง",
                "May mga taong nagbababa ng gamit",
            ),
        },
    },
    # --- common
    {
        "id": "count",
        "label": t("有幾個？", "How many?", "Có bao nhiêu?", "Berapa banyak?", "มีกี่ลำ/กี่ตัว?", "Ilan?"),
        "options": {
            "1": t("1", "1", "1", "1", "1", "1"),
            "2": t("2", "2", "2", "2", "2", "2"),
            "3plus": t("3 個以上", "3 or more", "3 trở lên", "3 atau lebih", "3 ขึ้นไป", "3 o higit pa"),
        },
    },
]
_BY_ID = {q["id"]: q for q in QUESTIONS}


def questionnaire(lang: str) -> dict:
    def pick(d: dict) -> str:
        return d.get(lang) or d["en"]

    return {
        "version": VERSION,
        "questions": [
            {
                "id": q["id"],
                "label": pick(q["label"]),
                "when": q.get("when"),
                "options": [{"value": v, "label": pick(lbl)} for v, lbl in q["options"].items()],
            }
            for q in QUESTIONS
        ],
    }


class InterviewError(ValueError):
    pass


@dataclass
class InterviewFacts:
    domain: str = "aerial"
    craft_type: str | None = None
    unmanned_surface: bool = False
    towards_shore: bool = False
    near_shore: bool = False
    shore_landing: bool = False
    count: int | None = None
    flags: list[str] = field(default_factory=list)


def _applies(q: dict, answers: dict) -> bool:
    return all(answers.get(k) in v for k, v in (q.get("when") or {}).items())


def evaluate(answers: dict | None, version: str | None = None) -> InterviewFacts:
    """Validate answers and derive facts. Unanswered questions are fine: speed beats completeness."""
    if not answers:
        return InterviewFacts()
    if version not in (None, VERSION):
        raise InterviewError(f"unknown interview version {version}")
    for k, v in answers.items():
        q = _BY_ID.get(k)
        if q is None:
            raise InterviewError(f"unknown question {k}")
        if v not in q["options"]:
            raise InterviewError(f"invalid answer for {k}")
        if not _applies(q, answers):
            raise InterviewError(f"question {k} does not apply")
    a = answers
    f = InterviewFacts(domain=a.get("domain", "aerial"))
    if f.domain == "aerial":
        f.craft_type = {"multirotor": "uav_multirotor", "fixed_wing": "uav_fixed_wing", "balloon": "balloon"}.get(
            a.get("aerial_type", ""), "uav"
        )
    elif f.domain == "surface":
        st = a.get("surface_type")
        crew = a.get("surface_crew")
        small = a.get("surface_size") in ("lt5", "5to20")
        f.unmanned_surface = st == "unmanned" or (crew == "no" and small and st != "ship")
        f.craft_type = (
            "usv"
            if f.unmanned_surface
            else {"speedboat": "small_boat", "fishing": "fishing_vessel", "ship": "ship"}.get(st or "", "vessel")
        )
    elif f.domain == "subsurface":
        f.craft_type = {"periscope": "submarine", "wake": "unknown_subsurface", "surfacing": "uuv"}.get(
            a.get("subsurface_seen", ""), "unknown_subsurface"
        )
    elif f.domain == "shore":
        seen = a.get("shore_seen")
        f.shore_landing = seen in ("boat_landed", "people_unloading")
        f.craft_type = {
            "boat_landed": "landed_boat",
            "object_ashore": "object_ashore",
            "people_unloading": "landed_boat",
        }.get(seen or "", None)
        if seen == "people_unloading":
            f.flags.append("people_unloading")
    f.towards_shore = a.get("surface_heading") == "towards_shore"
    f.near_shore = a.get("distance_offshore") == "lt500"
    f.count = {"1": 1, "2": 2, "3plus": 3}.get(a.get("count", ""))
    return f


DISTANCE_M = {"lt500": 300.0, "500to2000": 1200.0, "gt2000": 3500.0}
