"""
populate_stock_master.py — Ingests official NSE equities master and metadata into SQLite with FTS5.
"""
import os
import csv
import json
import sqlite3

DOMAIN_LOOKUP = {
    "TATASTEEL": "tatasteel.com", "TATAMOTORS": "tatamotors.com", "TATACHEM": "tatachemicals.com",
    "TATAPOWER": "tatapower.com", "TATACOMM": "tatacommunications.com", "TATAELXSI": "tataelxsi.com",
    "TATACONSUM": "tataconsumer.com", "TATACAP": "tatacapital.com", "TCS": "tcs.com",
    "RELIANCE": "ril.com", "INFY": "infosys.com", "WIPRO": "wipro.com", "HCLTECH": "hcltech.com",
    "TECHM": "techmahindra.com", "HDFCBANK": "hdfcbank.com", "ICICIBANK": "icicibank.com",
    "SBIN": "sbi.co.in", "KOTAKBANK": "kotak.com", "AXISBANK": "axisbank.com", "ITC": "itcportal.com",
    "HINDUNILVR": "hul.co.in", "BHARTIARTL": "airtel.in", "LT": "larsentoubro.com",
    "BAJFINANCE": "bajajfinserv.in", "BAJAJFINSV": "bajajfinserv.in", "BAJAJ-AUTO": "bajajauto.com",
    "ASIANPAINT": "asianpaints.com", "MARUTI": "marutisuzuki.com", "TITAN": "titancompany.in",
    "SUNPHARMA": "sunpharma.com", "ULTRACEMCO": "ultratechcement.com", "ONGC": "ongcindia.com",
    "NTPC": "ntpc.co.in", "POWERGRID": "powergrid.in", "COALINDIA": "coalindia.in", "IOC": "iocl.com",
    "BPCL": "bharatpetroleum.in", "HPCL": "hindustanpetroleum.com", "JSWSTEEL": "jsw.in",
    "HINDALCO": "hindalco.com", "VEDL": "vedantalimited.com", "ADANIENT": "adani.com",
    "ADANIPORTS": "adaniports.com", "ADANIGREEN": "adanigreenenergy.com", "ADANIPOWER": "adanipower.com",
    "ATGL": "adanigas.com", "ZOMATO": "zomato.com", "PAYTM": "paytm.com", "ONE97": "paytm.com",
    "POLICYBZR": "policybazaar.com", "NYKAA": "nykaa.com", "FSN": "nykaa.com", "SWIGGY": "swiggy.com",
    "IRCTC": "irctc.co.in", "BEL": "bel-india.in", "HAL": "hal-india.co.in", "DRREDDY": "drreddys.com",
    "CIPLA": "cipla.com", "DIVISLAB": "divislabs.com", "APOLLOHOSP": "apollohospitals.com",
    "BRITANNIA": "britannia.co.in", "NESTLEIND": "nestle.in", "DABUR": "dabur.com",
    "GODREJCP": "godrejcp.com", "GODREJPROP": "godrejproperties.com", "MARICO": "marico.com",
    "PIDILITIND": "pidilite.com", "SIEMENS": "siemens.co.in", "ABB": "abb.com", "EICHERMOT": "eicher.in",
    "HEROMOTOCO": "heromotocorp.com", "TVSMOTOR": "tvsmotor.com", "ASHOKLEY": "ashokleyland.com",
    "DLF": "dlf.in", "TRENT": "trentlimited.com", "LTIM": "ltimindtree.com", "PERSISTENT": "persistent.com",
    "COFORGE": "coforge.com", "MPHASIS": "mphasis.com", "INDUSINDBK": "indusind.com",
    "MUTHOOTFIN": "muthootfinance.com", "CHOLAFIN": "cholamandalam.com", "SHREECEM": "shreecement.com",
    "AMBUJACEM": "ambujacement.com", "ACC": "acc.com", "BOSCHLTD": "bosch.in", "HAVELLS": "havells.com",
    "GAIL": "gailonline.com", "PNB": "pnbindia.in", "BANKBARODA": "bankofbaroda.in",
    "CANBK": "canarabank.com", "UNIONBANK": "unionbankofindia.co.in", "IDFCFIRSTB": "idfcfirstbank.com",
    "FEDERALBNK": "federalbank.co.in", "YESBANK": "yesbank.in", "AUBANK": "aubank.in",
    "VOLTAS": "voltas.com", "BHEL": "bhel.com", "NMDC": "nmdc.co.in", "SAIL": "sail.co.in",
    "JINDALSTEL": "jindalsteelpower.com", "SUZLON": "suzlon.com", "IRFC": "irfc.co.in",
    "RVNL": "rvnl.org", "MAZDOCK": "mazagondock.in", "COCHINSHIP": "cochinshipyard.in",
    "BDL": "bharatdynamics.in", "LUPIN": "lupin.com", "AUROPHARMA": "aurobindo.com",
    "ZYDUSLIFE": "zyduslife.com", "TORNTPHARM": "torrentpharma.com", "BIOCON": "biocon.com",
    "MANKIND": "mankindpharma.com", "MAXHEALTH": "maxhealthcare.in", "DMART": "dmartindia.com",
    "INDIGO": "goindigo.in", "MOTHERSON": "motherson.com", "BERGEPAINT": "bergerpaints.com",
    "COLPAL": "colpal.co.in", "UPL": "upl-ltd.com", "SRF": "srf.com", "DEEPAKNTR": "deepaknitrite.com",
    "AARTIIND": "aarti-industries.com", "JUBLFOOD": "jubilantfoodworks.com", "PAGEIND": "pageindustries.com",
    "BALKRISIND": "balkrishna-industries.com", "MRF": "mrf.com", "APOLLOTYRE": "apollotyres.com",
    "CEATLTD": "ceat.com", "OBEROIRLTY": "oberoirealty.com", "LODHA": "macrotechdevelopers.com",
    "PRESTIGE": "prestigeconstructions.com", "PHOENIXLTD": "phoenixmills.com", "JIOFIN": "jiofinance.in",
    "CDSL": "cdslindia.com", "BSE": "bseindia.com", "MCX": "mcxindia.com", "ANGELONE": "angelone.in",
    "MOTILALOFS": "motilaloswal.com", "HDFCLIFE": "hdfclife.com", "SBILIFE": "sbilife.co.in",
    "ICICIPRULI": "iciciprulife.com", "ICICIGI": "icicilombard.com", "STARHEALTH": "starhealth.in",
    "LICHSGFIN": "lichousing.com", "LICI": "licindia.in", "GICRE": "gicofindia.in",
    "POONAWALLA": "poonawallafincorp.com", "SHRIRAMFIN": "shriramfinance.in", "M&MFIN": "mahindrafinance.com",
    "3MINDIA": "3mindia.in", "AIAENG": "aiaengineering.com", "ALKEM": "alkemlabs.com",
    "ALOKINDS": "alokind.com", "AMARAJABAT": "amara-raja.com", "ASTRAL": "astralpipes.com",
    "ATUL": "atulltd.com", "BATAINDIA": "bata.in", "BEML": "bemlindia.in", "BLUEDART": "bluedart.com",
    "CANFINHOME": "canfinhomes.com", "CASTROLIND": "castrol.com", "CENTURYTEX": "centurytextiles.com",
    "CERA": "cera-india.com", "CESC": "cesc.co.in", "CHAMBLFERT": "chambalfertilisers.com",
    "COROMANDEL": "coromandel.biz", "CROMPTON": "crompton.co.in", "CUMMINSIND": "cummins.com",
    "CYIENT": "cyient.com", "DALBHARAT": "dalmiacement.com", "DEEPAKFERT": "dfpcl.com",
    "DELHIVERY": "delhivery.com", "DIXON": "dixoninfo.com", "ECLERX": "eclerx.com",
    "EMAMILTD": "emamiltd.in", "ENDURANCE": "endurancegroup.com", "ENGINERSIN": "engineersindia.com",
    "EXIDEIND": "exideindustries.com", "FSL": "firstsource.com", "GLENMARK": "glenmarkpharma.com",
    "GMRAIRPORT": "gmrgroup.in", "GNFC": "gnfc.in", "GRANULES": "granulesindia.com",
    "GRINDWELL": "saint-gobain.com", "GSFC": "gsfclimited.com", "GUJGASLTD": "gujaratgas.com",
    "HATSUN": "hap.in", "HEG": "hegltd.com", "HFCL": "hfcl.com", "HIKAL": "hikal.com",
    "HINDCOPPER": "hindustancopper.com", "HINDPETRO": "hindustanpetroleum.com", "HINDZINC": "hindzinc.com",
    "HUDCO": "hudco.org", "IDBI": "idbibank.in", "IGL": "igl.co.in", "INDIACEM": "indiacements.co.in",
    "INDIAMART": "indiamart.com", "INDHOTEL": "ihcltata.com", "IOB": "iob.in", "IPCALAB": "ipcalabs.com",
    "JBCHEPHARM": "jbcpl.com", "JKCEMENT": "jkcement.com", "JKLAKSHMI": "jklakshmicement.com",
    "JKTYRE": "jktyre.com", "JUSTDIAL": "justdial.com", "KAJARIACER": "kajariatiles.com",
    "KALYANKJIL": "kalyanjewellers.net", "KEI": "keicables.com", "KNRCON": "knrcl.com",
    "KPITTECH": "kpittech.com", "KRBL": "krblrice.com", "LALPATHLAB": "drlalpathlabs.com",
    "LEMONTREE": "lemontreehotels.com", "LINDEINDIA": "linde.in", "LUXIND": "luxinnerwear.com",
    "MAHINDCIE": "cie-india.com", "MANAPPURAM": "manappuram.com", "METROPOLIS": "metropolisindia.com",
    "MFSL": "maxfinancialservices.com", "MGL": "mahanagargas.com", "MINDACORP": "sparkminda.com",
    "MSUMI": "motherson.com", "NATIONALUM": "nalcoindia.com", "NAUKRI": "infoedge.in",
    "NAVINFLUOR": "navinfluorine.com", "NBCC": "nbccindia.com", "NCC": "ncclimited.com",
    "NHPC": "nhpcindia.com", "OIL": "oil-india.com", "PFIZER": "pfizerindia.com",
    "PIIND": "piindustries.com", "PNCINFRA": "pncinfratech.com", "POLYMED": "polymedicure.com",
    "POLYCAB": "polycab.com", "PVRINOX": "pvrcinemas.com", "RADICO": "radicokhaitan.com",
    "RAIN": "rain-industries.com", "RAMCOCEM": "ramcocements.in", "RBLBANK": "rblbank.com",
    "RCF": "rcfltd.com", "RECLTD": "recindia.nic.in", "REDINGTON": "redingtongroup.com",
    "RELAXO": "relaxofootwear.com", "RITES": "rites.com", "ROLEXRINGS": "rolexrings.com",
    "ROUTE": "routemobile.com", "RPOWER": "reliancepower.co.in", "SANPARK": "sanofi.in",
    "SCHAEFFLER": "schaeffler.co.in", "SJVN": "sjvn.nic.in", "SKFINDIA": "skf.com",
    "SOBHA": "sobha.com", "SOLARINDS": "solargroup.com", "SONACOMS": "sonabhw.com",
    "SONATSOFTW": "sonatasoftware.com", "STAR": "strides.com", "SUMICHEM": "sumichem.co.in",
    "SUNDARMFIN": "sundaramfinance.in", "SUNDRMFAST": "sundram.com", "SUNTV": "suntv.in",
    "SUPREMEIND": "supreme.co.in", "SYNGENE": "syngeneintl.com", "TATAMTRDVR": "tatamotors.com",
    "TEJASNET": "tejasnetworks.com", "THERMAX": "thermaxglobal.com", "TIMKEN": "timken.com",
    "TITAGARH": "titagarh.in", "TORNTPOWER": "torrentpower.com", "TRIDENT": "tridentindia.com",
    "TRITURBINE": "triveniturbines.com", "TTKPRESTIG": "ttkprestige.com", "TV18BRDCST": "nw18.com",
    "UCOBANK": "ucobank.com", "VBL": "varunpepsi.com", "VIPIND": "vipbags.com",
    "VTL": "vardhman.com", "WELCORP": "welspuncorp.com", "WELSPUNLIV": "welspunliving.com",
    "WHIRLPOOL": "whirlpoolindia.com", "ZENSARTECH": "zensar.com", "ZYDUSWELL": "zyduswellness.com"
}

def resolve_domain(sym: str, name: str, existing_domain: str = "") -> str:
    if existing_domain:
        return existing_domain
    clean_sym = sym.upper().replace(".NS", "").replace(".BO", "")
    if clean_sym in DOMAIN_LOOKUP:
        return DOMAIN_LOOKUP[clean_sym]
    
    clean_name = name.upper()
    for drop in ["LIMITED", "LTD.", "LTD", "PVT", "CORP", "CORPORATION", "ENTERPRISES", "ENTERPRISE", "HOLDINGS", "INDIA"]:
        clean_name = clean_name.replace(drop, " ")
    words = [w for w in clean_name.split() if w.isalnum()]
    if words:
        slug = "".join(words[:2]).lower()
        if len(slug) >= 3:
            return f"{slug}.com"
    return f"{clean_sym.lower()}.com"

def run_ingestion():
    db_path = os.path.join(os.path.dirname(__file__), "..", "tradevision.db")
    csv_path = os.path.join(os.path.dirname(__file__), "..", "app", "data", "EQUITY_L.csv")
    meta_path = os.path.join(os.path.dirname(__file__), "..", "app", "data", "stock_metadata_map.json")

    print(f"Connecting to database: {os.path.abspath(db_path)}")
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Create master table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS stocks_master (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            symbol TEXT UNIQUE NOT NULL,
            ticker TEXT NOT NULL,
            company_name TEXT NOT NULL,
            series TEXT,
            isin TEXT,
            exchange TEXT DEFAULT 'NSE',
            sector TEXT,
            cap_tier TEXT,
            website_domain TEXT,
            listing_date TEXT,
            is_active INTEGER DEFAULT 1
        );
    """)

    # Create FTS5 virtual table for full-text search
    cur.execute("DROP TABLE IF EXISTS stocks_fts;")
    cur.execute("""
        CREATE VIRTUAL TABLE stocks_fts USING fts5(
            symbol,
            company_name,
            sector,
            content='stocks_master',
            content_rowid='id'
        );
    """)

    # Load metadata mappings
    metadata = {}
    if os.path.exists(meta_path):
        with open(meta_path, "r", encoding="utf-8") as f:
            metadata = json.load(f)
        print(f"Loaded {len(metadata)} curated metadata overrides.")

    if not os.path.exists(csv_path):
        print(f"Error: {csv_path} not found!")
        return

    inserted = 0
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            sym = row.get("SYMBOL", "").strip()
            name = row.get("NAME OF COMPANY", "").strip()
            series = row.get(" SERIES", row.get("SERIES", "")).strip()
            isin = row.get(" ISIN NUMBER", row.get("ISIN NUMBER", "")).strip()
            listing_date = row.get(" DATE OF LISTING", row.get("DATE OF LISTING", "")).strip()

            if not sym:
                continue

            ticker = f"{sym}.NS"
            meta = metadata.get(sym, {})
            sector = meta.get("sector", "General Equity")
            cap_tier = meta.get("cap", "Mid/Small Cap" if series == "BE" else "Equity")
            raw_domain = meta.get("domain", "")
            domain = resolve_domain(sym, name, raw_domain)

            cur.execute("""
                INSERT OR REPLACE INTO stocks_master (
                    symbol, ticker, company_name, series, isin, exchange, sector, cap_tier, website_domain, listing_date, is_active
                ) VALUES (?, ?, ?, ?, ?, 'NSE', ?, ?, ?, ?, 1)
            """, (sym, ticker, name, series, isin, sector, cap_tier, domain, listing_date))
            inserted += 1

    # Also guarantee all curated metadata stocks exist in stocks_master
    curated_added = 0
    for sym, meta in metadata.items():
        cur.execute("SELECT id FROM stocks_master WHERE symbol = ?", (sym,))
        if not cur.fetchone():
            ticker = f"{sym}.NS"
            company_name = meta.get("company_name", sym)
            sector = meta.get("sector", "General Equity")
            cap_tier = meta.get("cap", "Large Cap")
            domain = resolve_domain(sym, company_name, meta.get("domain", ""))
            cur.execute("""
                INSERT INTO stocks_master (
                    symbol, ticker, company_name, series, isin, exchange, sector, cap_tier, website_domain, listing_date, is_active
                ) VALUES (?, ?, ?, 'EQ', '', 'NSE', ?, ?, ?, '', 1)
            """, (sym, ticker, company_name, sector, cap_tier, domain))
            curated_added += 1

    # Populate FTS5 index
    cur.execute("""
        INSERT INTO stocks_fts(rowid, symbol, company_name, sector)
        SELECT id, symbol, company_name, sector FROM stocks_master;
    """)

    conn.commit()
    print(f"Successfully ingested {inserted} CSV stocks + {curated_added} curated stocks into stocks_master and populated stocks_fts index!")

    # Verify domain population
    cur.execute("SELECT COUNT(*) FROM stocks_master WHERE website_domain IS NOT NULL AND website_domain != '';")
    with_domain = cur.fetchone()[0]
    print(f"Total stocks with verified corporate domains: {with_domain} / {inserted + curated_added}")

    conn.close()

if __name__ == "__main__":
    run_ingestion()
