import fs from "node:fs/promises";
import path from "node:path";

const root = "/home/theotonin/Documentos/godot/o-farol";
const photoBytes = await fs.readFile(path.join(root, ".codex-build/tremembe/assets/fachada-tremembe.jpeg"));
const photo = `data:image/jpeg;base64,${photoBytes.toString("base64")}`;
const out = path.join(root, "output/slides/tremembe-prison-canva.html");

const esc = (value) => value.replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
const page = (label, notes, body, klass = "") => `<section class="page ${klass}" data-document-role="page" data-label="${esc(label)}" data-speaker-notes="${esc(notes)}">${body}</section>`;
const header = (n, kicker, title) => `<div class="top"><span>${kicker}</span><span>${String(n).padStart(2, "0")}</span></div><h1>${title}</h1>`;

const pages = [];
pages.push(page("Tremembé Prison", "Tremembé is a municipality in the Paraíba Valley, in the interior of São Paulo state. Its prison complex became nationally known because several inmates were connected to high-profile criminal cases. This presentation looks beyond the nickname and explains the institution's history, routine and changing role. Source: CNN Brasil, Aug. 22, 2025.", `
  <div class="cover-copy"><div class="eyebrow">BEHIND THE WALLS</div><div class="cover-rule"></div><div class="cover-title">Tremembé<br>Prison</div><div class="cover-sub">Behind Brazil's “Prison of Celebrities”</div><div class="cover-location">TREMEMBÉ, SÃO PAULO, BRAZIL</div><div class="presented">Presented by: [student names]</div></div>
  <img class="cover-photo" src="${photo}" alt="Exterior of Penitentiary II in Tremembé"><div class="pageno">01</div>
`, "cover"));

pages.push(page("Basic Facts", "The name Tremembé Prison can refer to more than one institution. The best-known unit is Penitentiary II Dr. José Augusto César Salgado, commonly called P2. Other units in the complex have different populations and security functions. São Paulo's prison administration records P2's inauguration on August 26, 1955. Sources: São Paulo State Prison Administration prison units and inauguration list. CNN Brasil, Aug. 22, 2025.", `
  ${header(2, "TREMEMBÉ PRISON", "Basic Facts")}
  <div class="two-col"><div><div class="eyebrow red">A COMPLEX, NOT A SINGLE BUILDING</div><ul><li>Five prison units in the complex</li><li>Facilities for men and women</li><li>Closed and semi-open regimes</li><li>P2 opened on August 26, 1955</li></ul></div><div class="year-box"><div class="year">1955</div><div class="gold-rule"></div><strong>Penitentiary II<br>Dr. José Augusto César Salgado</strong><small>The unit commonly called P2</small></div></div>
`));

pages.push(page("Why Did It Become Famous?", "People involved in cases with major public attention could face threats in ordinary prison populations. Tremembé became associated with protective separation and therefore concentrated several well-known names. The media nickname did not mean a luxury prison, and most prisoners were never celebrities. Source: CNN Brasil, Aug. 22, 2025.", `
  ${header(3, "TREMEMBÉ PRISON", "Why Did It Become Famous?")}
  <div class="big-quote">“PRISON OF CELEBRITIES”</div><div class="gold-rule wide"></div>
  <div class="reason"><b>01</b><strong>High-profile cases</strong><span>Several inmates appeared in major national news stories.</span></div>
  <div class="reason"><b>02</b><strong>Protection</strong><span>Authorities separated people who could face threats in ordinary prison populations.</span></div>
  <div class="reason"><b>03</b><strong>Media attention</strong><span>The concentration of well-known names created a lasting public image.</span></div>
  <div class="footnote">The nickname came from the media. It did not mean a luxury prison.</div>
`));

pages.push(page("Who Was Imprisoned There?", "These people were convicted in different cases that received extensive coverage in Brazil. Suzane von Richthofen was convicted for her role in the murder of her parents. Alexandre Nardoni was convicted in the death of his daughter Isabella. Elize Matsunaga and Cristian Cravinhos were also convicted in widely reported homicide cases. Keep the explanation neutral and avoid graphic details. Sources: CNN Brasil, Aug. 22, 2025 and Jan. 13, 2026.", `
  ${header(4, "TREMEMBÉ PRISON", "Who Was Imprisoned There?")}
  <div class="eyebrow red list-kicker">FORMER INMATES CONNECTED TO NATIONALLY KNOWN CASES</div>
  <div class="name-row"><b>01</b><strong>Suzane von Richthofen</strong><span>FORMER INMATE</span></div>
  <div class="name-row"><b>02</b><strong>Alexandre Nardoni</strong><span>FORMER INMATE</span></div>
  <div class="name-row"><b>03</b><strong>Elize Matsunaga</strong><span>FORMER INMATE</span></div>
  <div class="name-row"><b>04</b><strong>Cristian Cravinhos</strong><span>FORMER INMATE</span></div>
  <div class="caption">Each case received extensive media coverage in Brazil.</div>
`));

pages.push(page("Life Inside the Prison", "Official and reported programs have included workshops, schooling, religious activities, music or theatre, and prison labor. A state government report described an organic garden at P2 where incarcerated workers grew vegetables and herbs. These activities can build skills and responsibility. Work and study may also contribute to sentence reduction under Brazilian law when legal requirements are met. Sources: São Paulo State Prison Administration garden report. CNN Brasil, Aug. 22, 2025.", `
  ${header(5, "TREMEMBÉ PRISON", "Life Inside the Prison")}
  <div class="life-grid"><div><b>01</b><small>SECURITY</small><strong>Strict rules and daily routines</strong></div><div><b>02</b><small>WORK</small><strong>Prison labor and vocational activities</strong></div><div><b>03</b><small>EDUCATION</small><strong>Classes, culture and religious programs</strong></div><div><b>04</b><small>GARDEN</small><strong>Vegetable and herb production at P2</strong></div></div>
  <div class="banner">Official reports describe an organic garden where incarcerated workers grew vegetables and herbs.</div>
`));

pages.push(page("A Famous Story", "The Richthofen case became one of Brazil's most discussed criminal cases. Suzane spent roughly twenty years in the women's unit at Tremembé. In January 2023, the justice system moved her to the open regime. Her story helped build the complex's media image, but we should discuss it as a legal and social case, not as entertainment. Source: CNN Brasil, Aug. 22, 2025.", `
  ${header(6, "TREMEMBÉ PRISON", "A Famous Story")}
  <div class="story-name">SUZANE VON RICHTHOFEN</div><div class="story-sub">Her case became one of Brazil's most discussed criminal cases.</div>
  <div class="timeline"><div><b>2002</b><i></i><span>The crime drew<br>national attention</span></div><div><b>~20 YEARS</b><i></i><span>Sentence served largely<br>in Tremembé</span></div><div><b>2023</b><i></i><span>Moved to the<br>open regime</span></div></div>
  <div class="footnote center">A legal and social case, not entertainment</div>
`));

pages.push(page("The Prison Today", "Reports published in January 2026 said São Paulo authorities were dispersing notable prisoners to other facilities. Tremembé continues to operate, but its role as a single destination for famous inmates is changing. This matters because many older articles describe a situation that is no longer fully current. Sources: CNN Brasil, Jan. 13, 2026. São Paulo State Prison Administration prison units.", `
  ${header(7, "2026 UPDATE", "The Prison Today")}
  <div class="today-copy"><strong>The complex<br>remains active</strong><ul><li>Several high-profile inmates transferred</li><li>The special concentration began to end</li><li>Tremembé's public image still remains</li></ul></div>
  <img class="today-photo" src="${photo}" alt="Exterior of Penitentiary II in Tremembé"><div class="stamp">ROLE CHANGING</div>
  <div class="footnote">Reports in January 2026 described a new distribution policy for notable prisoners.</div>
`));

pages.push(page("Conclusion & Sources", "End by separating the media reputation from the institution's real functions. Tremembé matters because it shows how prison security, public attention and rehabilitation can intersect. Its role changed in 2026, but its history still influences public discussion about Brazil's prison system. Sources: SAP prison units, inauguration list and garden report. CNN Brasil, Aug. 22, 2025 and Jan. 13, 2026.", `
  ${header(8, "TREMEMBÉ PRISON", "Conclusion & Sources")}
  <div class="conclusion">Tremembé became famous because security decisions brought several high-profile inmates to the same complex.</div><div class="gold-rule wide"></div>
  <div class="eyebrow red debate">Its history connects three public debates:</div><div class="debates"><strong>PRISON SECURITY</strong><strong>MEDIA ATTENTION</strong><strong>REHABILITATION</strong></div>
  <div class="sources"><h2>Sources</h2><p>São Paulo State Prison Administration (SAP): prison units, inauguration list and prison garden report<br>CNN Brasil: Tremembé and the origin of its nickname, Aug. 22, 2025<br>CNN Brasil: transfers and the end of the special wing, Jan. 13, 2026</p></div><div class="thanks">Thank you</div>
`));

const html = `<!doctype html><html><head><meta charset="utf-8"><title>Tremembé Prison Presentation</title><style>
*{box-sizing:border-box}body{margin:0;background:#b8aea0;font-family:Arial,sans-serif;color:#301d17}.page{position:relative;width:1280px;height:720px;overflow:hidden;background:#e9deca;margin:0 auto 32px;padding:0 58px}.top{position:absolute;left:58px;right:58px;top:26px;height:54px;border-bottom:2px solid #4b2b20;display:flex;justify-content:space-between;color:#8f3d31;font:700 15px monospace;letter-spacing:.4px;padding:6px 10px 0 10px}.top span:last-child{color:#4b2b20;font-size:22px}h1{position:absolute;left:68px;top:94px;margin:0;font-size:38px;line-height:1.15}.eyebrow{font:700 16px monospace;color:#8f3d31}.red{color:#8f3d31}.cover{padding:0}.cover-copy{position:absolute;left:0;top:0;width:55%;height:100%;padding:52px 64px;background:#e9deca;z-index:2}.cover-photo{position:absolute;right:0;top:0;width:46%;height:100%;object-fit:cover}.cover-rule{height:3px;background:#4b2b20;margin-top:24px}.cover-title{font-size:70px;font-weight:700;line-height:1.05;margin-top:66px}.cover-sub{font-size:28px;font-style:italic;color:#4b2b20;margin-top:34px}.cover-location{font:700 16px monospace;color:#8f3d31;margin-top:130px}.presented{font-size:22px;margin-top:56px}.pageno{position:absolute;left:49%;bottom:48px;font:700 15px monospace;color:#766a60;z-index:3}.two-col{position:absolute;left:68px;right:68px;top:192px;display:grid;grid-template-columns:1fr 1fr;gap:76px}.two-col ul{font-size:27px;line-height:1.9;padding-left:36px}.year-box{height:390px;border:2px solid #4b2b20;background:#f4ebdd;text-align:center;padding:38px}.year{font:700 62px monospace;color:#8f3d31}.gold-rule{height:4px;background:#b78b4d;margin:25px 20px}.year-box strong{display:block;font-size:27px;line-height:1.3}.year-box small{display:block;font:15px monospace;color:#766a60;margin-top:42px}.big-quote{position:absolute;left:70px;top:205px;font:700 48px monospace;color:#8f3d31}.wide{position:absolute;left:62px;right:62px;top:282px;margin:0}.reason{position:relative;top:310px;height:102px;display:grid;grid-template-columns:80px 330px 1fr;align-items:start;padding:12px 20px;font-size:22px}.reason b{font:700 20px monospace;color:#8f3d31}.reason strong{font-size:27px}.footnote{position:absolute;left:74px;bottom:54px;font:700 15px monospace;color:#766a60}.center{left:0;right:0;text-align:center}.list-kicker{position:absolute;left:72px;top:183px}.name-row{position:relative;top:230px;height:102px;border-bottom:2px solid #b78b4d;display:grid;grid-template-columns:95px 1fr 180px;align-items:center;padding:0 12px}.name-row b{font:700 20px monospace;color:#8f3d31}.name-row strong{font-size:33px}.name-row span{font:700 13px monospace;color:#766a60;text-align:right}.caption{position:absolute;left:80px;bottom:48px;font-size:18px;font-style:italic;color:#766a60}.life-grid{position:absolute;left:68px;right:68px;top:210px;display:grid;grid-template-columns:repeat(4,1fr);gap:44px}.life-grid div{height:280px}.life-grid b{display:block;font:700 18px monospace;color:#8f3d31}.life-grid small{display:block;font:700 18px monospace;color:#4b2b20;margin-top:42px;border-bottom:3px solid #b78b4d;padding-bottom:24px}.life-grid strong{display:block;font-size:25px;margin-top:32px;line-height:1.35}.banner{position:absolute;left:66px;right:66px;bottom:95px;background:#4b2b20;color:#fff9ef;text-align:center;padding:28px;font-size:22px}.story-name{position:absolute;left:73px;top:190px;font:700 38px monospace;color:#8f3d31}.story-sub{position:absolute;left:75px;top:258px;font-size:24px;font-style:italic;color:#4b2b20}.timeline{position:absolute;left:90px;right:90px;top:340px;display:grid;grid-template-columns:repeat(3,1fr);gap:60px}.timeline:before{content:"";position:absolute;left:0;right:0;top:92px;height:5px;background:#4b2b20}.timeline div{text-align:center;z-index:1}.timeline b{font:700 22px monospace}.timeline i{display:block;width:40px;height:40px;background:#8f3d31;border:5px solid #e9deca;margin:50px auto 20px}.timeline span{font-size:20px;line-height:1.35;color:#4b2b20}.today-copy{position:absolute;left:80px;top:198px;width:490px}.today-copy>strong{font-size:46px;line-height:1.25}.today-copy ul{font-size:25px;line-height:1.8;margin-top:28px}.today-photo{position:absolute;right:60px;top:175px;width:505px;height:365px;object-fit:cover}.stamp{position:absolute;right:120px;top:490px;width:300px;background:#8f3d31;color:#fff9ef;text-align:center;padding:25px;font:700 22px monospace}.conclusion{position:absolute;left:75px;right:75px;top:190px;font-size:30px;font-weight:700;line-height:1.3}.debate{position:absolute;left:75px;top:330px}.debates{position:absolute;left:75px;right:75px;top:390px;display:flex;justify-content:space-between;font:700 22px monospace}.sources{position:absolute;left:76px;right:76px;top:465px}.sources h2{font-size:22px}.sources p{font-size:18px;line-height:1.5;color:#4b2b20}.thanks{position:absolute;right:78px;bottom:48px;font:700 15px monospace;color:#8f3d31}
</style></head><body>${pages.join("\n")}</body></html>`;
await fs.writeFile(out, html, "utf8");
console.log(out);
