import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const workspaceDir = "/home/theotonin/Documentos/godot/o-farol";
const SKILL_DIR = "/home/theotonin/.codex/plugins/cache/openai-primary-runtime/presentations/26.909.61513/skills/presentations";
const TMP_DIR = path.join(workspaceDir, ".codex-build/tremembe");
const FINAL_PPTX = path.join(workspaceDir, "output/slides/tremembe-prison-presentation-v3.pptx");
const RUNTIME_PYTHON = "/home/theotonin/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3";

const utils = await import(pathToFileURL(path.join(SKILL_DIR, "container_tools/artifact_tool_utils.mjs")).href);
const { finalizePresentation, makeNativeBulletParagraphs } = utils;

const W = 1280;
const H = 720;
const C = {
  paper: "#E9DECA",
  paper2: "#F4EBDD",
  ink: "#301D17",
  brown: "#4B2B20",
  brick: "#8F3D31",
  gold: "#B78B4D",
  gray: "#766A60",
  white: "#FFF9EF",
  black: "#17110F",
};
const FONT = "Liberation Sans";
const MONO = "DejaVu Sans Mono";

await fs.mkdir(TMP_DIR, { recursive: true });
await fs.mkdir(path.dirname(FINAL_PPTX), { recursive: true });
const photo = await fs.readFile(path.join(TMP_DIR, "assets/fachada-tremembe.jpeg"));

const deck = Presentation.create({ slideSize: { width: W, height: H } });

function addShape(slide, geometry, position, fill = "none", line = { fill: "none", width: 0 }) {
  return slide.shapes.add({ geometry, position, fill, line });
}

function addText(slide, text, x, y, w, h, opts = {}) {
  const box = addShape(slide, "textbox", { left: x, top: y, width: w, height: h });
  box.text = text;
  box.text.style = {
    typeface: opts.font ?? FONT,
    fontSize: opts.size ?? 28,
    bold: opts.bold ?? false,
    italic: opts.italic ?? false,
    color: opts.color ?? C.ink,
    alignment: opts.align ?? "left",
    verticalAlignment: opts.valign ?? "top",
    autoFit: "none",
  };
  return box;
}

function addRule(slide, x, y, w, color = C.brown, width = 2) {
  return addShape(slide, "line", { left: x, top: y, width: w, height: 0 }, "none", { style: "solid", fill: color, width });
}

function baseSlide(number, title, kicker = "TREMEMBÉ PRISON") {
  const slide = deck.slides.add();
  slide.background.fill = C.paper;
  addText(slide, kicker, 58, 34, 430, 28, { font: MONO, size: 15, bold: true, color: C.brick });
  addText(slide, String(number).padStart(2, "0"), 1150, 27, 72, 42, { font: MONO, size: 22, bold: true, color: C.brown, align: "right" });
  addRule(slide, 58, 78, 1164, C.brown, 2);
  addText(slide, title, 58, 102, 1100, 62, { size: 38, bold: true, color: C.ink });
  return slide;
}

function addBullets(slide, items, x, y, w, h, opts = {}) {
  const box = addShape(slide, "textbox", { left: x, top: y, width: w, height: h });
  box.text = makeNativeBulletParagraphs(items, {
    marginLeftPoints: opts.margin ?? 19,
    hangingPoints: opts.hanging ?? 9,
    spaceAfterPoints: opts.spaceAfter ?? 13,
  });
  box.text.style = {
    typeface: opts.font ?? FONT,
    fontSize: opts.size ?? 26,
    color: opts.color ?? C.ink,
    autoFit: "none",
  };
  return box;
}

function addNotes(slide, body, sources) {
  slide.speakerNotes.textFrame.setText(`${body}\n\nSources: ${sources.join(" | ")}`);
  slide.speakerNotes.setVisible(true);
}

// Slide 1
{
  const s = deck.slides.add();
  s.background.fill = C.paper;
  s.images.add({ blob: photo, contentType: "image/jpeg", alt: "Exterior of Penitentiary II in Tremembé, São Paulo", fit: "cover", position: { left: 690, top: 0, width: 590, height: 720 } });
  addShape(s, "rect", { left: 0, top: 0, width: 690, height: 720 }, C.paper, { fill: "none", width: 0 });
  addText(s, "BEHIND THE WALLS", 64, 52, 520, 30, { font: MONO, size: 16, bold: true, color: C.brick });
  addRule(s, 64, 96, 560, C.brown, 3);
  addText(s, "Tremembé\nPrison", 64, 138, 560, 180, { size: 70, bold: true, color: C.ink });
  addText(s, "Behind Brazil's “Prison of Celebrities”", 68, 340, 525, 82, { size: 28, italic: true, color: C.brown });
  addText(s, "TREMEMBÉ, SÃO PAULO, BRAZIL", 68, 505, 500, 32, { font: MONO, size: 16, bold: true, color: C.brick });
  addText(s, "Presented by: [student names]", 68, 575, 510, 36, { size: 22, color: C.ink });
  addText(s, "01", 585, 648, 60, 28, { font: MONO, size: 15, bold: true, color: C.gray, align: "right" });
  addNotes(s,
    "Tremembé is a municipality in the Paraíba Valley, in the interior of São Paulo state. Its prison complex became nationally known because several inmates were connected to high-profile criminal cases. This presentation looks beyond the nickname and explains the institution's history, routine and changing role.",
    ["CNN Brasil, Aug. 22, 2025: https://www.cnnbrasil.com.br/nacional/sudeste/sp/tremembe-entenda-de-onde-surgiu-fama-de-presidio-dos-famosos/"]);
}

// Slide 2
{
  const s = baseSlide(2, "Basic Facts");
  addText(s, "A COMPLEX, NOT A SINGLE BUILDING", 62, 183, 620, 30, { font: MONO, size: 15, bold: true, color: C.brick });
  addBullets(s, [
    "Five prison units in the complex",
    "Facilities for men and women",
    "Closed and semi-open regimes",
    "P2 opened on August 26, 1955",
  ], 68, 225, 560, 340, { size: 27, spaceAfter: 17 });
  addShape(s, "rect", { left: 715, top: 190, width: 495, height: 390 }, C.paper2, { style: "solid", fill: C.brown, width: 2 });
  addText(s, "1955", 765, 225, 390, 85, { font: MONO, size: 62, bold: true, color: C.brick, align: "center" });
  addRule(s, 765, 326, 390, C.gold, 3);
  addText(s, "Penitentiary II\nDr. José Augusto César Salgado", 770, 358, 380, 110, { size: 27, bold: true, color: C.ink, align: "center" });
  addText(s, "The unit commonly called P2", 785, 505, 350, 34, { font: MONO, size: 15, color: C.gray, align: "center" });
  addNotes(s,
    "The name Tremembé Prison can refer to more than one institution. The best-known unit is Penitentiary II Dr. José Augusto César Salgado, commonly called P2. Other units in the complex have different populations and security functions. São Paulo's prison administration records P2's inauguration on August 26, 1955.",
    ["São Paulo State Prison Administration, prison units: https://www1.sap.sp.gov.br/sp/unidades-prisionais/unidades-prisionais-mobile-ceprvali.html", "SAP, Inaugurated Units: https://www1.sap.sp.gov.br/sp/unidades-prisionais/impressao/pdf/inauguradas.pdf", "CNN Brasil, Aug. 22, 2025"]);
}

// Slide 3
{
  const s = baseSlide(3, "Why Did It Become Famous?");
  addText(s, "“PRISON OF CELEBRITIES”", 62, 190, 1150, 72, { font: MONO, size: 48, bold: true, color: C.brick });
  addRule(s, 62, 280, 1145, C.gold, 4);
  const rows = [
    ["01", "High-profile cases", "Several inmates appeared in major national news stories."],
    ["02", "Protection", "Authorities separated people who could face threats in ordinary prison populations."],
    ["03", "Media attention", "The concentration of well-known names created a lasting public image."],
  ];
  let y = 320;
  for (const [n, head, body] of rows) {
    addText(s, n, 68, y, 56, 42, { font: MONO, size: 20, bold: true, color: C.brick });
    addText(s, head, 150, y - 3, 315, 45, { size: 27, bold: true, color: C.ink });
    addText(s, body, 480, y, 690, 63, { size: 22, color: C.brown });
    y += 102;
  }
  addText(s, "The nickname came from the media. It did not mean a luxury prison.", 64, 645, 1120, 34, { font: MONO, size: 15, bold: true, color: C.gray });
  addNotes(s,
    "People involved in cases with major public attention could face threats in ordinary prison populations. Tremembé became associated with protective separation and therefore concentrated several well-known names. The media nickname did not mean a luxury prison, and most prisoners were never celebrities.",
    ["CNN Brasil, Aug. 22, 2025: https://www.cnnbrasil.com.br/nacional/sudeste/sp/tremembe-entenda-de-onde-surgiu-fama-de-presidio-dos-famosos/"]);
}

// Slide 4
{
  const s = baseSlide(4, "Who Was Imprisoned There?");
  addText(s, "FORMER INMATES CONNECTED TO NATIONALLY KNOWN CASES", 62, 177, 1000, 28, { font: MONO, size: 14, bold: true, color: C.brick });
  const names = ["Suzane von Richthofen", "Alexandre Nardoni", "Elize Matsunaga", "Cristian Cravinhos"];
  let y = 230;
  names.forEach((name, i) => {
    addText(s, String(i + 1).padStart(2, "0"), 70, y + 5, 70, 42, { font: MONO, size: 20, bold: true, color: C.brick });
    addText(s, name, 165, y, 875, 55, { size: 33, bold: true, color: C.ink });
    addText(s, "FORMER INMATE", 1040, y + 12, 165, 28, { font: MONO, size: 13, bold: true, color: C.gray, align: "right" });
    addRule(s, 70, y + 67, 1135, C.gold, 1.5);
    y += 102;
  });
  addText(s, "Each case received extensive media coverage in Brazil.", 70, 646, 1040, 30, { size: 18, italic: true, color: C.gray });
  addNotes(s,
    "These people were convicted in different cases that received extensive coverage in Brazil. Suzane von Richthofen was convicted for her role in the murder of her parents. Alexandre Nardoni was convicted in the death of his daughter Isabella. Elize Matsunaga and Cristian Cravinhos were also convicted in widely reported homicide cases. Keep the explanation neutral and avoid graphic details.",
    ["CNN Brasil, Aug. 22, 2025", "CNN Brasil, Jan. 13, 2026: https://www.cnnbrasil.com.br/nacional/sudeste/sp/presidio-dos-famosos-comeca-a-ser-desfeito-e-presos-sao-transferidos/"]);
}

// Slide 5
{
  const s = baseSlide(5, "Life Inside the Prison");
  const items = [
    ["SECURITY", "Strict rules and daily routines"],
    ["WORK", "Prison labor and vocational activities"],
    ["EDUCATION", "Classes, culture and religious programs"],
    ["GARDEN", "Vegetable and herb production at P2"],
  ];
  let x = 68;
  items.forEach(([head, body], i) => {
    addText(s, String(i + 1).padStart(2, "0"), x, 205, 68, 40, { font: MONO, size: 18, bold: true, color: C.brick });
    addText(s, head, x, 263, 245, 35, { font: MONO, size: 18, bold: true, color: C.brown });
    addRule(s, x, 312, 245, C.gold, 3);
    addText(s, body, x, 340, 245, 135, { size: 25, bold: true, color: C.ink });
    x += 295;
  });
  addShape(s, "rect", { left: 66, top: 535, width: 1138, height: 90 }, C.brown, { fill: "none", width: 0 });
  addText(s, "Official reports describe an organic garden where incarcerated workers grew vegetables and herbs.", 95, 557, 1080, 48, { size: 22, color: C.white, align: "center" });
  addNotes(s,
    "Official and reported programs have included workshops, schooling, religious activities, music or theatre, and prison labor. A state government report described an organic garden at P2 where incarcerated workers grew vegetables and herbs. These activities can build skills and responsibility. Work and study may also contribute to sentence reduction under Brazilian law when legal requirements are met.",
    ["São Paulo State Prison Administration, prison gardens: https://www1.sap.sp.gov.br/noticias/not1932.html", "CNN Brasil, Aug. 22, 2025"]);
}

// Slide 6
{
  const s = baseSlide(6, "A Famous Story");
  addText(s, "SUZANE VON RICHTHOFEN", 63, 180, 1020, 60, { font: MONO, size: 38, bold: true, color: C.brick });
  addText(s, "Her case became one of Brazil's most discussed criminal cases.", 65, 250, 1000, 40, { size: 24, italic: true, color: C.brown });
  addRule(s, 90, 420, 1090, C.brown, 5);
  const milestones = [
    [140, "2002", "The crime drew\nnational attention"],
    [515, "~20 YEARS", "Sentence served largely\nin Tremembé"],
    [910, "2023", "Moved to the\nopen regime"],
  ];
  milestones.forEach(([x, year, body]) => {
    addShape(s, "rect", { left: x, top: 402, width: 40, height: 40 }, C.brick, { style: "solid", fill: C.paper, width: 5 });
    addText(s, year, x - 62, 330, 165, 46, { font: MONO, size: 22, bold: true, color: C.ink, align: "center" });
    addText(s, body, x - 78, 476, 200, 84, { size: 20, color: C.brown, align: "center" });
  });
  addText(s, "A legal and social case, not entertainment", 65, 640, 1110, 28, { font: MONO, size: 15, bold: true, color: C.gray, align: "center" });
  addNotes(s,
    "The Richthofen case became one of Brazil's most discussed criminal cases. Suzane spent roughly twenty years in the women's unit at Tremembé. In January 2023, the justice system moved her to the open regime. Her story helped build the complex's media image, but we should discuss it as a legal and social case, not as entertainment.",
    ["CNN Brasil, Aug. 22, 2025: https://www.cnnbrasil.com.br/nacional/sudeste/sp/tremembe-entenda-de-onde-surgiu-fama-de-presidio-dos-famosos/"]);
}

// Slide 7
{
  const s = deck.slides.add();
  s.background.fill = C.paper;
  s.images.add({ blob: photo, contentType: "image/jpeg", alt: "Exterior of Penitentiary II in Tremembé", fit: "cover", position: { left: 700, top: 175, width: 505, height: 365 } });
  addText(s, "2026 UPDATE", 58, 34, 430, 28, { font: MONO, size: 15, bold: true, color: C.brick });
  addText(s, "07", 1150, 27, 72, 42, { font: MONO, size: 22, bold: true, color: C.brown, align: "right" });
  addRule(s, 58, 78, 1164, C.brown, 2);
  addText(s, "The Prison Today", 58, 102, 1100, 62, { size: 38, bold: true, color: C.ink });
  addText(s, "The complex\nremains active", 68, 190, 540, 100, { size: 46, bold: true, color: C.ink });
  addBullets(s, [
    "Several high-profile inmates transferred",
    "The special concentration began to end",
    "Tremembé's public image still remains",
  ], 75, 330, 535, 260, { size: 25, spaceAfter: 15 });
  addShape(s, "rect", { left: 850, top: 490, width: 300, height: 88 }, C.brick, { fill: "none", width: 0 });
  addText(s, "ROLE CHANGING", 858, 513, 285, 40, { font: MONO, size: 22, bold: true, color: C.white, align: "center" });
  addText(s, "Reports in January 2026 described a new distribution policy for notable prisoners.", 70, 630, 1120, 38, { font: MONO, size: 15, color: C.gray });
  addNotes(s,
    "Reports published in January 2026 said São Paulo authorities were dispersing notable prisoners to other facilities. Tremembé continues to operate, but its role as a single destination for famous inmates is changing. This matters because many older articles describe a situation that is no longer fully current.",
    ["CNN Brasil, Jan. 13, 2026: https://www.cnnbrasil.com.br/nacional/sudeste/sp/presidio-dos-famosos-comeca-a-ser-desfeito-e-presos-sao-transferidos/", "São Paulo State Prison Administration, prison units"]);
}

// Slide 8
{
  const s = baseSlide(8, "Conclusion & Sources");
  addText(s, "Tremembé became famous because security decisions brought several high-profile inmates to the same complex.", 66, 180, 1110, 83, { size: 30, bold: true, color: C.ink });
  addRule(s, 66, 282, 1138, C.gold, 4);
  addText(s, "Its history connects three public debates:", 66, 310, 620, 38, { font: MONO, size: 16, bold: true, color: C.brick });
  addText(s, "PRISON SECURITY", 70, 370, 340, 40, { font: MONO, size: 22, bold: true, color: C.brown });
  addText(s, "MEDIA ATTENTION", 470, 370, 340, 40, { font: MONO, size: 22, bold: true, color: C.brown });
  addText(s, "REHABILITATION", 875, 370, 330, 40, { font: MONO, size: 22, bold: true, color: C.brown });
  addText(s, "Sources", 68, 465, 170, 32, { size: 22, bold: true, color: C.ink });
  addText(s,
    "São Paulo State Prison Administration (SAP): prison units, inauguration list and prison garden report\nCNN Brasil: Tremembé and the origin of its nickname, Aug. 22, 2025\nCNN Brasil: transfers and the end of the special wing, Jan. 13, 2026",
    68, 510, 1125, 125, { size: 18, color: C.brown });
  addText(s, "Thank you", 1010, 654, 180, 28, { font: MONO, size: 15, bold: true, color: C.brick, align: "right" });
  addNotes(s,
    "End by separating the media reputation from the institution's real functions. Tremembé matters because it shows how prison security, public attention and rehabilitation can intersect. Its role changed in 2026, but its history still influences public discussion about Brazil's prison system.",
    ["SAP prison units: https://www1.sap.sp.gov.br/sp/unidades-prisionais/unidades-prisionais-mobile-ceprvali.html", "SAP inauguration list: https://www1.sap.sp.gov.br/sp/unidades-prisionais/impressao/pdf/inauguradas.pdf", "SAP garden report: https://www1.sap.sp.gov.br/noticias/not1932.html", "CNN Brasil, Aug. 22, 2025", "CNN Brasil, Jan. 13, 2026"]);
}

const requirements = {
  explicitTotalSlideCount: 8,
  requiredNativeTableOwnerSlides: [],
  requiredNativeChartOwnerSlides: [],
};
const fontPolicy = { basis: "design", families: [FONT, MONO] };
const expectedSlideSizeEmu = "12192000,6858000";
const stagingDir = path.join(workspaceDir, ".codex-finalizer-tremembe");
await fs.mkdir(stagingDir, { recursive: true });
const candidatePath = path.join(stagingDir, "candidate.pptx");
await (await PresentationFile.exportPptx(deck)).save(candidatePath);

await finalizePresentation({
  ...requirements,
  workspaceDir,
  candidatePath,
  finalPath: FINAL_PPTX,
  pythonExecutable: RUNTIME_PYTHON,
  integrityValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_package_integrity.py"),
  layoutValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_layout_geometry.py"),
  layoutArgs: ["--expected-slide-size-emu", expectedSlideSizeEmu, "--validate-bullet-geometry", "--validate-heading-fit"],
  requiredNativeTableOwnerSlides: [],
  fontPolicy,
  verifyArtifactToolImport: true,
  receiptPath: path.join(stagingDir, "tremembe-prison-presentation-v3.validation.json"),
});

console.log(FINAL_PPTX);
