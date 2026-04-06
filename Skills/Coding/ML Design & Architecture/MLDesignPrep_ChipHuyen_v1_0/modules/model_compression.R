# modules/model_compression.R
# Model Compression, Optimisation & Computation Graphs — Ch.7 deep dive
# Interactive computation graphs for ResNet, BERT, GPT-2, MobileNet, YOLOv8

model_compression_ui <- function(id) {
  ns <- NS(id)

  # ── Inline CSS ─────────────────────────────────────────────────────────────
  css <- "
  /* ── Computation graph styles ── */
  .cg-wrap {
    position: relative;
    background: #fff;
    border-radius: 10px;
    overflow: hidden;
    border: 1px solid #e0e0e0;
  }
  .cg-wrap svg { display:block; width:100%; height:auto; }

  /* Clickable nodes */
  .cg-node { cursor:pointer; transition: filter 0.18s; }
  .cg-node:hover { filter: brightness(0.88) drop-shadow(0 3px 8px rgba(0,138,130,0.45)); }
  .cg-node.selected { filter: drop-shadow(0 0 6px #008A82); }

  /* Detail panel */
  .cg-detail {
    background: linear-gradient(135deg,#f0fafa,#e8f5f4);
    border: 1.5px solid #80cbc4;
    border-left: 5px solid #008A82;
    border-radius: 10px;
    padding: 16px 20px;
    margin-top: 12px;
    display: none;
    animation: cgFade 0.2s ease;
  }
  .cg-detail.show { display:block; }
  @keyframes cgFade { from{opacity:0;transform:translateY(-6px)} to{opacity:1;transform:translateY(0)} }
  .cg-detail h4 { color:#002C3C; font-weight:800; font-size:14px; margin:0 0 8px; }
  .cg-detail p  { color:#2c3e50; font-size:12.5px; line-height:1.7; margin:0 0 6px; }
  .cg-detail ul { padding-left:18px; margin:6px 0; }
  .cg-detail li { color:#2c3e50; font-size:12px; line-height:1.7; }
  .cg-tag { display:inline-block; background:#008A82; color:#fff; border-radius:12px; padding:2px 10px; font-size:10px; font-weight:700; margin:2px 2px 6px; }
  .cg-tag.orange { background:#e67e22; }
  .cg-tag.red    { background:#c0392b; }
  .cg-tag.blue   { background:#2980b9; }
  .cg-tag.grey   { background:#607d8b; }
  .cg-close { float:right; background:none; border:none; color:#80cbc4; font-size:18px; cursor:pointer; padding:0; line-height:1; }
  .cg-close:hover { color:#008A82; }

  /* Model selector tabs */
  .model-selector {
    display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 14px;
  }
  .model-btn {
    padding: 6px 16px; border-radius: 20px; border: 2px solid #b2dfdb;
    background: #fff; color: #008A82; font-size: 11px; font-weight: 700;
    cursor: pointer; transition: all 0.18s; letter-spacing: 0.3px;
  }
  .model-btn:hover  { background:#e0f4f2; border-color:#008A82; }
  .model-btn.active { background:#002C3C; border-color:#002C3C; color:#fff; }

  /* Compression comparison table */
  .comp-table { width:100%; border-collapse:collapse; font-size:12px; }
  .comp-table th { background:#002C3C; color:#fff; padding:8px 12px; text-align:left; font-size:11px; letter-spacing:0.5px; }
  .comp-table td { padding:8px 12px; border-bottom:1px solid #f0f0f0; color:#2c3e50; }
  .comp-table tr:nth-child(even) td { background:#f9fffe; }
  .comp-table tr:hover td { background:#e0f4f2; }
  .bar-cell { position:relative; }
  .bar-bg   { position:absolute; left:0; top:4px; bottom:4px; background:linear-gradient(90deg,#008A82,#00A39A); border-radius:2px; opacity:0.25; }
  .bar-val  { position:relative; z-index:1; }

  /* Quant precision pill */
  .prec-pill {
    display:inline-block; border-radius:6px; padding:3px 10px;
    font-size:10px; font-weight:800; letter-spacing:0.5px; margin:2px;
  }
  .fp32  { background:#fce4ec; color:#880e4f; border:1px solid #f48fb1; }
  .fp16  { background:#e3f2fd; color:#0d47a1; border:1px solid #90caf9; }
  .bf16  { background:#e8f5e9; color:#1b5e20; border:1px solid #a5d6a7; }
  .int8  { background:#fff8e1; color:#e65100; border:1px solid #ffe082; }
  .int4  { background:#f3e5f5; color:#4a148c; border:1px solid #ce93d8; }

  /* Compression flow */
  .cflow-step {
    display:flex; align-items:flex-start; gap:14px; margin-bottom:14px;
    padding:12px 14px; background:#f8fffe; border-radius:8px;
    border-left:4px solid #008A82;
  }
  .cflow-num {
    width:28px; height:28px; border-radius:50%; flex-shrink:0;
    background:linear-gradient(135deg,#008A82,#00A39A);
    color:#fff; font-weight:800; font-size:13px;
    display:flex; align-items:center; justify-content:center;
  }
  .cflow-body h6 { margin:0 0 4px; font-size:13px; font-weight:700; color:#002C3C; }
  .cflow-body p  { margin:0; font-size:12px; color:#546e7a; line-height:1.6; }
  "

  # ── Computation graph SVG data ─────────────────────────────────────────────
  # These are accurate architectural representations as SVG with clickable nodes

  graph_js <- "
<script>
// ── Computation Graph interaction engine ──────────────────────────────────
var CG_DATA = {};

// Node detail content for each model
CG_DATA[\"resnet\"] = {
  \"input\":       {title:\"Input Image  224×224×3\", tags:[\"Tensor\",\"float32\",\"150,528 values\"], body:\"Standard ImageNet input. 224×224 RGB image normalised to mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225]. Batch dimension prepended: [B, 3, 224, 224].\", extra:\"Memory: ~2.4 MB per image at FP32. Quantise to INT8 → 0.6 MB.\"},
  \"conv1\":       {title:\"Conv2d  7×7, stride=2, pad=3 → 112×112×64\", tags:[\"Conv\",\"Learnable\",\"9,408 params\"], body:\"Stem convolution. Aggressive downsampling from 224→112 halves spatial resolution immediately. 7×7 kernel sees large receptive field in first layer — captures low-level edges at multiple orientations.\", extra:\"FLOPs: 118M. Compression tip: replace with 3× 3×3 convs (Bag of Tricks) for better accuracy with same compute.\"},
  \"bn1\":         {title:\"BatchNorm2d  + ReLU  →  112×112×64\", tags:[\"Normalisation\",\"4 params/channel\",\"Fused in inference\"], body:\"BatchNorm normalises over batch dimension. At inference, BN is fused with preceding Conv into a single linear op — γ(Wx+b-μ)/σ+β becomes W\\'x+b\\'. This fusion is critical for inference speed.\", extra:\"BN fusion: eliminates separate BN operation. ~15% latency reduction on CPU.\"},
  \"maxpool\":     {title:\"MaxPool  3×3, stride=2  →  56×56×64\", tags:[\"Pooling\",\"No params\",\"112→56\"], body:\"Further halves spatial resolution. Combined with Conv1, the stem reduces 224×224 → 56×56 (16× fewer spatial positions). This is where most spatial compute is saved.\", extra:\"Alternative: use stride-2 conv instead of MaxPool for learnable downsampling.\"},
  \"layer1\":      {title:\"Layer 1: 3× BasicBlock  →  56×56×64\", tags:[\"Residual\",\"2 Convs per block\",\"x3\"], body:\"First residual stage. Each BasicBlock: Conv3×3 → BN → ReLU → Conv3×3 → BN → +identity → ReLU. Identity shortcut: output = F(x) + x. Solves vanishing gradient for deep networks.\", extra:\"Params: 147,456. Residual connection = gradient highway. Enables 100+ layer networks.\"},
  \"layer2\":      {title:\"Layer 2: 4× BasicBlock  stride=2  →  28×28×128\", tags:[\"Residual\",\"Downsampling\",\"x4\"], body:\"Doubles channels (64→128), halves spatial (56→28). First block uses stride=2 + projection shortcut (1×1 Conv) to match dimensions. Subsequent blocks use identity shortcut.\", extra:\"FLOPs: 1.2B in this stage. Pruning here saves the most compute.\"},
  \"layer3\":      {title:\"Layer 3: 6× BasicBlock  stride=2  →  14×14×256\", tags:[\"Residual\",\"Deepest stage\",\"x6\"], body:\"Deepest stage — most residual blocks. Spatial 28→14, channels 128→256. This is where the network learns highest-level semantic features: object parts, textures.\", extra:\"Distillation typically targets this layer\\'s features as the teacher signal.\"},
  \"layer4\":      {title:\"Layer 4: 3× BasicBlock  stride=2  →  7×7×512\", tags:[\"Residual\",\"Final stage\",\"x3\"], body:\"Final convolutional stage. 7×7 feature maps contain rich semantic representations. For ResNet-50+, Bottleneck blocks used here: 1×1 → 3×3 → 1×1 Conv reduces params vs BasicBlock.\", extra:\"7×7×512 = 25,088 values. GAP collapses this to 512 — eliminates spatial dependency.\"},
  \"gap\":         {title:\"GlobalAveragePool  →  512\", tags:[\"Pooling\",\"No params\",\"Spatial invariance\"], body:\"Global Average Pooling collapses 7×7×512 → 512 by averaging each channel spatially. Critical design choice: replaces FC layers at the end, making the model input-size agnostic and dramatically reducing params.\", extra:\"Alternative: GlobalMaxPool or concatenate both. GAP acts as structural regulariser.\"},
  \"fc\":          {title:\"Linear  512 → 1000  + Softmax\", tags:[\"Classification head\",\"512,000 params\",\"ImageNet-1K\"], body:\"Final fully-connected layer maps 512-dim embedding to 1000 class logits. Softmax converts to probabilities. For transfer learning: replace with Linear(512, num_classes). Only 0.1% of total params.\", extra:\"Swap for your task: Linear(512, 1) for regression, Linear(512, num_classes) for classification.\"}
};

CG_DATA[\"bert\"] = {
  \"tokens\":      {title:\"Token IDs  →  [B, 512]\", tags:[\"Discrete\",\"WordPiece\",\"30,522 vocab\"], body:\"Input text tokenised with WordPiece. [CLS] prepended for classification, [SEP] separates segments. Max sequence length 512. Padding with [PAD]=0.\", extra:\"Tokenisation is a preprocessing bottleneck. BertTokenizerFast uses Rust — 100× faster than Python tokeniser.\"},
  \"embed\":       {title:\"Token + Position + Segment Embeddings  →  [B, 512, 768]\", tags:[\"Lookup table\",\"23.8M params\",\"Three embeddings summed\"], body:\"Three embedding tables summed: (1) Token: 30,522 × 768, (2) Position: 512 × 768 (learned, not sinusoidal unlike original Transformer), (3) Segment: 2 × 768 (sentence A/B). LayerNorm + Dropout applied.\", extra:\"23.8M params in embeddings alone = 37% of BERT-base. Distillation replaces these with smaller tables.\"},
  \"attn1\":       {title:\"Multi-Head Self-Attention  12 heads, 64 dim each  →  [B, 512, 768]\", tags:[\"Attention\",\"O(n²) complexity\",\"Learnable Q/K/V\"], body:\"BERT uses bidirectional self-attention. Q=K=V=input (self-attention). 12 heads × 64 dim = 768. Attention weights: softmax(QKᵀ/√64). Each head specialises: some attend to syntax, others to semantics, coreference.\", extra:\"Flash Attention: recomputes attention in SRAM tiles → 2-4× faster, 10× less memory. Critical for long sequences.\"},
  \"ffn1\":        {title:\"FFN: Linear 768→3072 → GELU → Linear 3072→768\", tags:[\"Feed-forward\",\"4× expansion\",\"47.2M params\"], body:\"Position-wise FFN. Expansion factor 4×: 768→3072→768. GELU activation (smoother than ReLU). Each token processed independently — the FFN is where facts are stored in BERT according to recent interpretability research.\", extra:\"FFN params = 2 × (768×3072 + 3072×768) = 47.2M per layer × 12 layers = 566M just in FFNs.\"},
  \"stack\":       {title:\"×12 Transformer Blocks (Encoder)\", tags:[\"12 layers\",\"110M total params\",\"Pre-trained on 3.3B tokens\"], body:\"BERT-base stacks 12 identical encoder blocks: MHA → Add+Norm → FFN → Add+Norm. Pre-trained on BookCorpus + Wikipedia with MLM (mask 15% tokens, predict them) and NSP (next sentence prediction).\", extra:\"Layer depth matters: lower layers = syntax (POS, dependency), upper layers = semantics (NER, coreference). Prune from the top for most tasks.\"},
  \"pooler\":      {title:\"Pooler: [CLS] token → Linear(768,768) → Tanh\", tags:[\"Classification\",\"CLS token\",\"Optional\"], body:\"Extracts [CLS] token representation. Linear + Tanh projects to 768-dim. For sequence classification: pass pooler output to classification head. For token tasks (NER): use all token representations directly.\", extra:\"Controversy: [CLS] pooler vs mean pooling of all tokens. Sentence-BERT shows mean pooling better for semantic similarity.\"},
  \"head\":        {title:\"Task Head  →  Output\", tags:[\"Fine-tuned\",\"Task-specific\",\"Few params\"], body:\"BERT is pre-trained then fine-tuned. Classification head: Linear(768, num_labels). NER head: Linear(768, num_labels) per token. QA head: two Linear(768,1) for start/end span positions.\", extra:\"Fine-tuning cost: BERT-base on SST-2 in ~20 minutes on 1×V100. LoRA reduces this to 5 minutes, 1/8 the memory.\"}
};

CG_DATA[\"gpt2\"] = {
  \"tokens\":      {title:\"Token IDs  →  [B, T]\", tags:[\"BPE\",\"50,257 vocab\",\"Max 1024 tokens\"], body:\"GPT-2 uses Byte-Pair Encoding tokenisation. 50,257 vocab including special tokens. Supports up to 1024 context length. Unlike BERT, no [CLS]/[SEP] — causal language model.\", extra:\"Tiktoken (used by GPT-3/4): Rust BPE implementation, ~100× faster than original GPT-2 tokeniser.\"},
  \"wte_wpe\":     {title:\"Token Embedding + Positional Embedding  →  [B, T, 768]\", tags:[\"Learned position\",\"50,257×768\",\"1024×768\"], body:\"Token embedding: 50,257 × 768 = 38.6M params. Positional embedding: 1024 × 768 = 0.8M params (learned absolute position, unlike sinusoidal in original Transformer). Summed element-wise.\", extra:\"GPT-2 uses learned positional embeddings. GPT-3 uses rotary PE (RoPE). Modern LLMs prefer RoPE/ALiBi for length generalisation.\"},
  \"ln1\":         {title:\"LayerNorm  →  [B, T, 768]\", tags:[\"Pre-norm\",\"No batch dependency\",\"4 params\"], body:\"GPT-2 uses Pre-LN (LayerNorm before attention), unlike original Transformer\\'s Post-LN. Pre-LN critical for training stability at scale — gradients stay well-conditioned throughout 48+ layers.\", extra:\"Pre-norm vs Post-norm: Pre-norm models train stably without learning rate warmup. Post-norm models can achieve slightly better final accuracy if tuned carefully.\"},
  \"causal_attn\": {title:\"Causal Multi-Head Attention  12 heads  →  [B, T, 768]\", tags:[\"Causal mask\",\"O(T²) memory\",\"KV cache at inference\"], body:\"Causal (decoder-only) attention: each token can only attend to itself and previous tokens. Causal mask: upper triangular matrix of -∞ added before softmax. KV cache: store K,V for all previous tokens during generation — avoids recomputing.\", extra:\"KV cache memory: 2 × layers × heads × head_dim × T × batch × dtype_bytes. GPT-2: 24 × 12 × 64 × T × B × 4 bytes. Paged attention (vLLM) manages this as virtual memory pages.\"},
  \"ffn_gpt\":     {title:\"FFN: Linear 768→3072 → GELU → Linear 3072→768\", tags:[\"4× expansion\",\"47.2M params\",\"Per-token\"], body:\"Same 4× expansion as BERT but GPT-2 uses original GELU (not approximated). Modern LLMs use SwiGLU/GeGLU: x × sigmoid(1.702x) — smoother, better perplexity. LLaMA uses SwiGLU.\", extra:\"FFN stores factual knowledge: factual associations are encoded in key-value memories in FFN weights (Geva et al., 2021).\"},
  \"blocks_gpt\":  {title:\"×12 Transformer Blocks (Decoder)\", tags:[\"12 layers\",\"117M params\",\"Autoregressive\"], body:\"12 identical decoder blocks. Pre-LN architecture. No cross-attention (encoder-decoder) — pure decoder-only autoregressive. Output of layer L feeds into layer L+1.\", extra:\"GPT-2 sizes: Small(117M), Medium(345M), Large(762M), XL(1.5B). Modern scaling: GPT-3=175B, GPT-4~1.8T (estimated MoE).\"},
  \"ln_f\":        {title:\"Final LayerNorm  →  [B, T, 768]\", tags:[\"Pre-LN final\",\"Stabilises output\",\"Same scale as input\"], body:\"Final layer normalisation applied after all transformer blocks. Ensures output distribution is consistent for the language model head.\", extra:\"\"},
  \"lm_head\":     {title:\"LM Head: Linear(768, 50257) — tied weights\", tags:[\"Weight tying\",\"50,257 logits\",\"38.6M params\"], body:\"Language model head projects hidden states to vocabulary logits. Weight tying: LM head shares weights with token embedding table (transposed). Reduces params by 38.6M and improves training stability.\", extra:\"Sampling strategies: Greedy (argmax), Top-k (sample from top k), Top-p nucleus (sample from top probability mass p), Temperature (T<1=conservative, T>1=creative).\"}
};

CG_DATA[\"mobilenet\"] = {
  \"input_mb\":    {title:\"Input  224×224×3\", tags:[\"Mobile input\",\"Standard size\",\"Edge deployment\"], body:\"MobileNet designed for mobile/edge inference. Same 224×224 input as ResNet but radically different internal computation. Width multiplier α ∈ (0,1] scales all channels. α=1.0 = full model.\", extra:\"For edge: α=0.25 → 41× fewer computations than ResNet-50, 3.4× fewer than MobileNet-V1 α=1.\"},
  \"dw_sep1\":     {title:\"Depthwise Separable Conv  3×3 DW + 1×1 PW  →  112×112×32\", tags:[\"Key innovation\",\"8-9× fewer ops\",\"Depthwise + Pointwise\"], body:\"MobileNet\\'s core innovation. Standard Conv(3×3, C_in, C_out): C_in × C_out × 9 multiplies per position. Depthwise Sep: (1) DW conv: C_in × 9 per position (one filter per channel); (2) PW conv: C_in × C_out × 1 per position. Total: C_in(9 + C_out) vs standard C_in × C_out × 9.\", extra:\"Reduction factor: (9 + C_out) / (9 × C_out) ≈ 1/9 for large C_out. At C_out=32: 8.9× reduction. This is why MobileNet can run real-time on CPU.\"},
  \"dw_sep2\":     {title:\"DW Sep Conv  stride=2  →  56×56×64\", tags:[\"Downsampling\",\"DW Sep Conv\",\"Stride in DW layer\"], body:\"Strided depthwise conv (stride=2 in DW layer) performs spatial downsampling while separable structure keeps FLOPs minimal. 112×112 → 56×56.\", extra:\"\"},
  \"dw_stack\":    {title:\"×11 DW Separable Conv blocks  →  7×7×1024\", tags:[\"Progressive downsampling\",\"Main body\",\"All DW Sep\"], body:\"11 depthwise separable blocks with progressive channel doubling: 64→128→128→256→256→512(×5)→1024. Each doubling accompanied by stride-2 downsampling. This is the entire feature extraction backbone.\", extra:\"Total backbone FLOPs: 569M vs ResNet-50\\'s 4.1B. 7.2× less compute for comparable accuracy.\"},
  \"gap_mb\":      {title:\"Global Average Pool  7×7×1024  →  1024\", tags:[\"Pooling\",\"Spatial collapse\",\"No params\"], body:\"Same GAP as ResNet. Collapses 7×7×1024 to 1024-dim vector. Makes model input-size flexible.\", extra:\"\"},
  \"fc_mb\":       {title:\"Linear  1024 → 1000  + Softmax\", tags:[\"Classification head\",\"Swappable\",\"1024×1000 params\"], body:\"Classification head. For mobile deployment replace with smaller head. MobileNet-V2 uses Conv2d head (not FC) to reduce params.\", extra:\"MobileNetV2 top improvement: inverted residuals with linear bottlenecks. V3: Neural Architecture Search + SE modules + h-swish activation.\"}
};

CG_DATA[\"yolo\"] = {
  \"input_yolo\":  {title:\"Input  640×640×3\", tags:[\"YOLO standard\",\"Letterboxed\",\"Multi-scale\"], body:\"YOLOv8 standard input 640×640. Images letterboxed (padded with grey) to preserve aspect ratio. Supports multi-scale training: randomly resize to [480, 512, ..., 640, 672, ..., 800] during training for better small-object detection.\", extra:\"Tile inference: divide large image into overlapping tiles, run YOLO per tile, merge predictions with NMS. Handles very high-res images.\"},
  \"backbone\":    {title:\"CSP-DarkNet53 Backbone  →  80×80, 40×40, 20×20 feature maps\", tags:[\"YOLOv8 backbone\",\"Cross-Stage Partial\",\"Multi-scale outputs\"], body:\"CSPDarkNet uses Cross-Stage Partial connections: split feature map into two paths, one goes through residual blocks, one bypasses — then concat. Reduces gradient recomputation. Outputs three scales: P3(80×80), P4(40×40), P5(20×20) for multi-scale detection.\", extra:\"Darknet-53 roots: 53-layer DarkNet with residual blocks, adapted from ResNet. C2f modules in YOLOv8 (inspired by ELAN from YOLOv7).\"},
  \"neck\":        {title:\"PANet Neck: FPN top-down + PAN bottom-up  →  fused P3/P4/P5\", tags:[\"Feature Pyramid\",\"PANet\",\"Multi-scale fusion\"], body:\"Path Aggregation Network fuses multi-scale features bidirectionally. FPN (top-down): upsample P5→P4→P3 to add semantic info to high-res maps. PAN (bottom-up): downsample P3→P4→P5 to add localisation info to low-res maps. Both paths then concatenated at each scale.\", extra:\"This is why YOLO detects small objects well (uses high-res P3 with semantic context from P5) and large objects well (P5 has large receptive field).\"},
  \"head\":        {title:\"Decoupled Detection Head  3 scales × (4 + num_classes)\", tags:[\"Anchor-free\",\"Decoupled\",\"YOLOv8 innovation\"], body:\"YOLOv8 uses anchor-free detection with decoupled heads (separate box regression and classification branches). Each scale predicts: 4 values (x,y,w,h using DFL — Distribution Focal Loss) + num_classes probabilities. No objectness score (removed in v8).\", extra:\"DFL: instead of predicting bbox directly, predict distribution over discrete offsets. Reduces regression ambiguity. Enables sub-pixel localisation.\"},
  \"nms\":         {title:\"NMS: Non-Maximum Suppression  →  Final detections\", tags:[\"Post-processing\",\"IoU threshold\",\"Not learned\"], body:\"Remove duplicate detections. For each class: (1) sort by confidence, (2) keep highest confidence box, (3) remove boxes with IoU > threshold with kept box, (4) repeat. IoU threshold typically 0.45-0.65.\", extra:\"NMS bottleneck: cannot be parallelised efficiently (sequential). Soft-NMS, WBF (Weighted Boxes Fusion) are better alternatives. TensorRT NMS plugin accelerates this 10×.\"}
};

// ── Active state ─────────────────────────────────────────────────────────
var CG_ACTIVE_MODEL = \"resnet\";
var CG_ACTIVE_NODE  = null;

function cgSelectModel(m) {
  CG_ACTIVE_MODEL = m;
  CG_ACTIVE_NODE  = null;
  // Show/hide SVG graphs
  [\"resnet\",\"bert\",\"gpt2\",\"mobilenet\",\"yolo\"].forEach(function(id){
    var el = document.getElementById(\"cg-svg-\" + id);
    if (el) el.style.display = id === m ? \"block\" : \"none\";
  });
  // Update buttons
  document.querySelectorAll(\".model-btn\").forEach(function(b){
    b.classList.toggle(\"active\", b.dataset.model === m);
  });
  // Clear detail
  var det = document.getElementById(\"cg-detail-panel\");
  if (det) { det.className = \"cg-detail\"; det.innerHTML = \"\"; }
  // Clear node highlights
  document.querySelectorAll(\".cg-node\").forEach(function(n){ n.classList.remove(\"selected\"); });
}

function cgNodeClick(nodeId) {
  var data = CG_DATA[CG_ACTIVE_MODEL];
  if (!data || !data[nodeId]) return;
  var d = data[nodeId];
  var det = document.getElementById(\"cg-detail-panel\");
  if (!det) return;

  // Clear previous selection
  document.querySelectorAll(\".cg-node\").forEach(function(n){ n.classList.remove(\"selected\"); });
  // Highlight selected
  var nodeEl = document.getElementById(\"cgn-\" + nodeId);
  if (nodeEl) nodeEl.classList.add(\"selected\");

  // Build tags
  var tagsHtml = (d.tags||[]).map(function(t){
    var cls = \"cg-tag\";
    if (t.includes(\"param\") || t.includes(\"param\")) cls += \" grey\";
    if (t.includes(\"O(n\") || t.includes(\"bottleneck\")) cls += \" red\";
    if (t.includes(\"Learned\") || t.includes(\"Learnable\")) cls += \" blue\";
    return '<span class=\"' + cls + '\">' + t + '</span>';
  }).join(\"\");

  det.innerHTML = '<button class=\"cg-close\" onclick=\"cgCloseDetail()\">&#10005;</button>' +
    '<h4>' + d.title + '</h4>' +
    tagsHtml +
    '<p style=\"margin-top:8px\">' + d.body + '</p>' +
    (d.extra ? '<p style=\"background:#fff;border-radius:6px;padding:8px;font-size:11.5px;color:#546e7a;margin-top:6px;border:1px solid #cceae8;\">' + d.extra + '</p>' : \"\");
  det.className = \"cg-detail show\";
  setTimeout(function(){ det.scrollIntoView({behavior:\"smooth\",block:\"nearest\"}); }, 50);
}

function cgCloseDetail() {
  var det = document.getElementById(\"cg-detail-panel\");
  if (det) { det.className = \"cg-detail\"; }
  document.querySelectorAll(\".cg-node\").forEach(function(n){ n.classList.remove(\"selected\"); });
}

// Init on load
(function(){
  function init(){
    cgSelectModel(\"resnet\");
  }
  if (document.readyState === \"loading\") document.addEventListener(\"DOMContentLoaded\", init);
  else setTimeout(init, 50);
})();
</script>"

  # ── SVG Computation Graphs ─────────────────────────────────────────────────
  # Each graph is a detailed, accurate representation of the model architecture

  # Helper to build a node
  cg_node <- function(id, x, y, w, h, label, sublabel="", fill="#e0f4f2", stroke="#008A82", text_col="#002C3C") {
    paste0(
      sprintf('<g id="cgn-%s" class="cg-node" onclick="cgNodeClick(\'%s\')">', id, id),
      sprintf('<rect x="%s" y="%s" width="%s" height="%s" rx="6" fill="%s" stroke="%s" stroke-width="2"/>', x, y, w, h, fill, stroke),
      sprintf('<text x="%s" y="%s" text-anchor="middle" font-size="10.5" font-weight="700" fill="%s">%s</text>', x+w/2, y+h/2+(if(sublabel!="") -5 else 4), text_col, label),
      if (sublabel != "") sprintf('<text x="%s" y="%s" text-anchor="middle" font-size="8.5" fill="%s" opacity="0.8">%s</text>', x+w/2, y+h/2+8, text_col, sublabel) else "",
      '</g>'
    )
  }
  arr <- function(x1,y1,x2,y2,col="#008A82",dash=FALSE) {
    paste0(sprintf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.8"%s marker-end="url(#cgArr)"/>',
      x1,y1,x2,y2,col, if(dash) ' stroke-dasharray="5,3"' else ''))
  }
  defs_svg <- '<defs><marker id="cgArr" markerWidth="7" markerHeight="5" refX="7" refY="2.5" orient="auto"><polygon points="0 0,7 2.5,0 5" fill="#008A82"/></marker></defs>'

  # ── ResNet-50 Graph ──────────────────────────────────────────────────────
  resnet_svg <- paste0(
    '<svg id="cg-svg-resnet" viewBox="0 0 780 520" xmlns="http://www.w3.org/2000/svg" style="font-family:Arial,sans-serif;background:#fafafa;width:100%;height:auto;">',
    defs_svg,
    # Title
    '<text x="390" y="22" text-anchor="middle" font-size="13" font-weight="800" fill="#002C3C">ResNet-50 — Computation Graph</text>',
    '<text x="390" y="38" text-anchor="middle" font-size="9.5" fill="#546e7a">25.6M params | 4.1B FLOPs | Top-1: 76.1% ImageNet — click any node</text>',

    # Input
    cg_node("input",  305, 50, 170, 38, "Input Image", "224×224×3", "#fff3e0","#e67e22","#bf360c"),
    arr(390, 88, 390, 108),

    # Stem
    '<rect x="180" y="108" width="420" height="115" rx="8" fill="none" stroke="#b2dfdb" stroke-width="1.5" stroke-dasharray="6,3"/>',
    '<text x="192" y="122" font-size="9" fill="#80cbc4" font-weight="700">STEM</text>',
    cg_node("conv1",  240, 128, 170, 36, "Conv2d 7×7 s=2", "→112×112×64", "#e3f2fd","#2980b9","#0d47a1"),
    cg_node("bn1",    460, 128, 170, 36, "BatchNorm + ReLU", "fused at inference", "#e8f5e9","#27ae60","#1b5e20"),
    arr(410, 146, 460, 146),
    cg_node("maxpool",350, 185, 170, 30, "MaxPool 3×3 s=2", "→56×56×64", "#f3e5f5","#8e44ad","#4a148c"),
    arr(390, 164, 390, 185),
    arr(390, 215, 390, 235),

    # Residual stages
    '<rect x="120" y="235" width="540" height="220" rx="8" fill="none" stroke="#b2dfdb" stroke-width="1.5" stroke-dasharray="6,3"/>',
    '<text x="132" y="249" font-size="9" fill="#80cbc4" font-weight="700">RESIDUAL STAGES</text>',

    cg_node("layer1", 140, 255, 140, 44, "Layer 1 × 3", "56×56×64  BasicBlock", "#e0f4f2","#008A82","#002C3C"),
    cg_node("layer2", 300, 255, 140, 44, "Layer 2 × 4", "28×28×128  s=2", "#e0f4f2","#008A82","#002C3C"),
    cg_node("layer3", 460, 255, 140, 44, "Layer 3 × 6", "14×14×256  s=2", "#e0f4f2","#008A82","#002C3C"),
    cg_node("layer4", 300, 320, 140, 44, "Layer 4 × 3", "7×7×512  s=2", "#c8e6c9","#1a9b6b","#003320"),
    arr(280, 277, 300, 277),
    arr(440, 277, 460, 277),
    arr(530, 299, 530, 342), arr(530, 342, 440, 342),
    '<text x="550" y="325" font-size="9" fill="#546e7a">spatial</text>',
    '<text x="550" y="337" font-size="9" fill="#546e7a">→ 7×7</text>',

    # Residual skip illustration
    '<path d="M 540 260 Q 580 260 580 300 Q 580 340 540 340" fill="none" stroke="#e67e22" stroke-width="1.5" stroke-dasharray="4,3"/>',
    '<text x="585" y="302" font-size="8" fill="#e67e22" font-weight="700">skip</text>',
    '<text x="585" y="313" font-size="8" fill="#e67e22">connections</text>',

    arr(370, 342, 370, 375),
    cg_node("gap",    285, 375, 170, 36, "Global Average Pool", "7×7×512 → 512", "#fff9c4","#f39c12","#e65100"),
    arr(370, 411, 370, 435),
    cg_node("fc",     285, 435, 170, 36, "Linear 512→1000", "Softmax → class probs", "#ffebee","#c0392b","#7f0000"),
    wc <- '</svg>'
  )

  # ── BERT Graph ───────────────────────────────────────────────────────────
  bert_svg <- paste0(
    '<svg id="cg-svg-bert" viewBox="0 0 780 560" xmlns="http://www.w3.org/2000/svg" style="font-family:Arial,sans-serif;background:#fafafa;width:100%;height:auto;display:none;">',
    defs_svg,
    '<text x="390" y="22" text-anchor="middle" font-size="13" font-weight="800" fill="#002C3C">BERT-base — Computation Graph</text>',
    '<text x="390" y="38" text-anchor="middle" font-size="9.5" fill="#546e7a">110M params | Bidirectional | Pre-trained on 3.3B tokens — click any node</text>',

    # Input
    cg_node("tokens",  305, 52, 170, 36, "Token IDs", "[B, 512]  WordPiece vocab", "#fff3e0","#e67e22","#bf360c"),
    arr(390, 88, 390, 108),

    # Embedding layer
    cg_node("embed",  250, 108, 280, 50, "Token + Position + Segment Embeddings", "[B, 512, 768]  — 23.8M params", "#e3f2fd","#2980b9","#0d47a1"),
    arr(390, 158, 390, 185),

    # Transformer block (shown once, labelled ×12)
    '<rect x="100" y="185" width="580" height="250" rx="10" fill="rgba(0,138,130,0.04)" stroke="#80cbc4" stroke-width="2"/>',
    '<text x="113" y="202" font-size="9.5" font-weight="700" fill="#008A82">TRANSFORMER ENCODER BLOCK  ×12</text>',

    # Inside block
    cg_node("attn1",   140, 212, 240, 46, "Multi-Head Self-Attention", "12 heads × 64 dim  Q/K/V projections", "#e0f4f2","#008A82","#002C3C"),
    # Add & Norm
    '<rect x="140" y="268" width="240" height="26" rx="5" fill="#f5f5f5" stroke="#ccc" stroke-width="1"/>',
    '<text x="260" y="285" text-anchor="middle" font-size="9.5" fill="#546e7a">Add &amp; LayerNorm</text>',
    arr(260, 258, 260, 268),
    # Residual skip for attention
    '<path d="M 395 218 Q 420 218 420 258 Q 420 283 395 283" fill="none" stroke="#e67e22" stroke-width="1.5" stroke-dasharray="4,3"/>',
    '<text x="424" y="255" font-size="8" fill="#e67e22">skip</text>',

    arr(260, 294, 260, 314),
    cg_node("ffn1",    140, 314, 240, 46, "FFN: 768→3072→768", "GELU activation  47.2M params/layer", "#e8f5e9","#1a9b6b","#003320"),
    '<rect x="140" y="370" width="240" height="26" rx="5" fill="#f5f5f5" stroke="#ccc" stroke-width="1"/>',
    '<text x="260" y="387" text-anchor="middle" font-size="9.5" fill="#546e7a">Add &amp; LayerNorm</text>',
    arr(260, 360, 260, 370),
    '<path d="M 395 320 Q 420 320 420 370 Q 420 390 395 390" fill="none" stroke="#e67e22" stroke-width="1.5" stroke-dasharray="4,3"/>',

    # Bidirectional attention label
    cg_node("stack",   460, 212, 195, 185, "Bidirectional", "", "#f3e5f5","#8e44ad","#4a148c"),
    '<text x="557" y="252" text-anchor="middle" font-size="9" fill="#4a148c" font-weight="700">All tokens attend</text>',
    '<text x="557" y="265" text-anchor="middle" font-size="9" fill="#4a148c">to all tokens</text>',
    '<text x="557" y="285" text-anchor="middle" font-size="9" fill="#8e44ad">← LEFT context</text>',
    '<text x="557" y="300" text-anchor="middle" font-size="9" fill="#8e44ad">RIGHT context →</text>',
    '<text x="557" y="320" text-anchor="middle" font-size="9" fill="#4a148c">Pre-trained: MLM</text>',
    '<text x="557" y="335" text-anchor="middle" font-size="9" fill="#4a148c">Fine-tuned: task head</text>',
    '<text x="557" y="360" text-anchor="middle" font-size="8.5" fill="#7e57c2">× 12 identical blocks</text>',
    '<text x="557" y="374" text-anchor="middle" font-size="8.5" fill="#7e57c2">stacked vertically</text>',

    arr(260, 396, 260, 425),
    cg_node("pooler", 175, 425, 170, 36, "Pooler [CLS] token", "Linear(768,768) + Tanh", "#fff9c4","#f39c12","#e65100"),
    arr(260, 461, 260, 485),
    cg_node("head",   175, 485, 170, 36, "Task Head", "Classification / NER / QA", "#ffebee","#c0392b","#7f0000"),
    '</svg>'
  )

  # ── GPT-2 Graph ──────────────────────────────────────────────────────────
  gpt2_svg <- paste0(
    '<svg id="cg-svg-gpt2" viewBox="0 0 780 560" xmlns="http://www.w3.org/2000/svg" style="font-family:Arial,sans-serif;background:#fafafa;width:100%;height:auto;display:none;">',
    defs_svg,
    '<text x="390" y="22" text-anchor="middle" font-size="13" font-weight="800" fill="#002C3C">GPT-2 (small) — Computation Graph</text>',
    '<text x="390" y="38" text-anchor="middle" font-size="9.5" fill="#546e7a">117M params | Causal/Autoregressive | KV-cache at inference — click any node</text>',

    cg_node("tokens",   305, 52, 170, 36, "Token IDs", "[B, T]  BPE 50,257 vocab", "#fff3e0","#e67e22","#bf360c"),
    arr(390, 88, 390, 108),
    cg_node("wte_wpe",  225, 108, 310, 44, "Token Embed + Positional Embed", "[B, T, 768]  WTE(50257×768) + WPE(1024×768)", "#e3f2fd","#2980b9","#0d47a1"),
    arr(390, 152, 390, 178),

    '<rect x="100" y="178" width="580" height="275" rx="10" fill="rgba(0,44,60,0.03)" stroke="#80cbc4" stroke-width="2"/>',
    '<text x="113" y="195" font-size="9.5" font-weight="700" fill="#008A82">TRANSFORMER DECODER BLOCK  ×12  (Pre-LN architecture)</text>',

    cg_node("ln1",       195, 205, 130, 30, "LayerNorm", "Pre-norm", "#f5f5f5","#888","#333"),
    arr(325, 220, 345, 220),
    cg_node("causal_attn",345, 205, 240, 52, "Causal Self-Attention", "12 heads | causal mask | KV-cache", "#e0f4f2","#008A82","#002C3C"),
    '<path d="M 195 225 Q 160 225 160 270 Q 160 290 195 290" fill="none" stroke="#e67e22" stroke-width="1.5" stroke-dasharray="4,3"/>',
    '<text x="130" y="260" font-size="8" fill="#e67e22">residual</text>',
    '<rect x="195" y="267" width="390" height="24" rx="5" fill="#f5f5f5" stroke="#ccc" stroke-width="1"/>',
    '<text x="390" y="283" text-anchor="middle" font-size="9" fill="#546e7a">Add &amp; LayerNorm (Pre-LN)</text>',
    arr(390, 257, 390, 267),
    arr(390, 291, 390, 315),

    cg_node("ffn_gpt",   195, 315, 390, 50, "FFN: Linear(768→3072) → GELU → Linear(3072→768)", "4× expansion  47.2M params  stores factual knowledge", "#e8f5e9","#1a9b6b","#003320"),
    '<path d="M 195 330 Q 155 330 155 375 Q 155 400 195 400" fill="none" stroke="#e67e22" stroke-width="1.5" stroke-dasharray="4,3"/>',
    '<rect x="195" y="375" width="390" height="24" rx="5" fill="#f5f5f5" stroke="#ccc" stroke-width="1"/>',
    '<text x="390" y="391" text-anchor="middle" font-size="9" fill="#546e7a">Add &amp; LayerNorm</text>',
    arr(390, 365, 390, 375),

    # Causal mask illustration
    '<rect x="620" y="210" width="135" height="135" rx="6" fill="white" stroke="#ccc" stroke-width="1"/>',
    '<text x="687" y="226" text-anchor="middle" font-size="8" font-weight="700" fill="#c0392b">CAUSAL MASK</text>',
    # Draw lower triangular mask
    paste(sapply(0:4, function(i) paste(sapply(0:4, function(j) {
      if (j <= i) sprintf('<rect x="%s" y="%s" width="18" height="18" rx="2" fill="#008A82" opacity="0.7"/>', 625+j*22, 232+i*22)
      else sprintf('<rect x="%s" y="%s" width="18" height="18" rx="2" fill="#ffcdd2"/>', 625+j*22, 232+i*22)
    }), collapse="")), collapse=""),
    '<text x="687" y="350" text-anchor="middle" font-size="7.5" fill="#546e7a">Each token sees</text>',
    '<text x="687" y="362" text-anchor="middle" font-size="7.5" fill="#546e7a">only past tokens</text>',

    cg_node("blocks_gpt", 450, 205, 150, 185, "", "", "rgba(0,0,0,0)","rgba(0,0,0,0)","#002C3C"),

    arr(390, 399, 390, 425),
    cg_node("ln_f",    280, 425, 220, 30, "Final LayerNorm", "", "#f5f5f5","#888","#333"),
    arr(390, 455, 390, 478),
    cg_node("lm_head", 235, 478, 310, 40, "LM Head  Linear(768→50257)", "Weight-tied with WTE  →  next token logits", "#ffebee","#c0392b","#7f0000"),
    '</svg>'
  )

  # ── MobileNet Graph ──────────────────────────────────────────────────────
  mobilenet_svg <- paste0(
    '<svg id="cg-svg-mobilenet" viewBox="0 0 780 460" xmlns="http://www.w3.org/2000/svg" style="font-family:Arial,sans-serif;background:#fafafa;width:100%;height:auto;display:none;">',
    defs_svg,
    '<text x="390" y="22" text-anchor="middle" font-size="13" font-weight="800" fill="#002C3C">MobileNet-V1 — Computation Graph</text>',
    '<text x="390" y="38" text-anchor="middle" font-size="9.5" fill="#546e7a">4.2M params | 569M FLOPs | Designed for mobile/edge — click any node</text>',

    cg_node("input_mb",  305, 52, 170, 36, "Input Image", "224×224×3", "#fff3e0","#e67e22","#bf360c"),
    arr(390, 88, 390, 110),

    cg_node("dw_sep1", 245, 110, 290, 46, "Depthwise Sep Conv  3×3 DW + 1×1 PW  s=2", "KEY INNOVATION  8-9× fewer FLOPs than standard conv", "#e3f2fd","#2980b9","#0d47a1"),

    # DW sep illustration
    '<rect x="30" y="105" width="195" height="145" rx="8" fill="#f8fffe" stroke="#b2dfdb" stroke-width="1.5"/>',
    '<text x="127" y="120" text-anchor="middle" font-size="8.5" font-weight="700" fill="#008A82">Standard Conv vs DW Sep</text>',
    '<text x="60" y="138" text-anchor="middle" font-size="8" fill="#c0392b">Standard Conv</text>',
    '<rect x="35" y="142" width="45" height="45" rx="3" fill="#ffcdd2" stroke="#c0392b" stroke-width="1.5"/>',
    '<text x="57" y="165" text-anchor="middle" font-size="7.5" fill="#c0392b">C_out filters</text>',
    '<text x="57" y="177" text-anchor="middle" font-size="7.5" fill="#c0392b">3×3×C_in each</text>',
    '<text x="60" y="198" text-anchor="middle" font-size="7.5" fill="#c0392b">C_in×C_out×9</text>',
    '<text x="60" y="208" text-anchor="middle" font-size="7.5" fill="#c0392b">FLOPs</text>',
    '<text x="155" y="138" text-anchor="middle" font-size="8" fill="#008A82">DW Sep Conv</text>',
    '<rect x="115" y="142" width="38" height="45" rx="3" fill="#c8e6c9" stroke="#008A82" stroke-width="1.5"/>',
    '<text x="134" y="162" text-anchor="middle" font-size="7" fill="#008A82">DW: 1 filter</text>',
    '<text x="134" y="172" text-anchor="middle" font-size="7" fill="#008A82">per channel</text>',
    '<text x="134" y="184" text-anchor="middle" font-size="7" fill="#008A82">3×3×1 each</text>',
    '<rect x="162" y="142" width="55" height="45" rx="3" fill="#e8f5e9" stroke="#27ae60" stroke-width="1.5"/>',
    '<text x="189" y="162" text-anchor="middle" font-size="7" fill="#27ae60">PW: C_out</text>',
    '<text x="189" y="172" text-anchor="middle" font-size="7" fill="#27ae60">1×1 filters</text>',
    '<text x="134" y="200" text-anchor="middle" font-size="7.5" fill="#008A82">C_in×9 + C_in×C_out</text>',
    '<text x="134" y="212" text-anchor="middle" font-size="7.5" fill="#008A82">≈ 8-9× less</text>',

    arr(390, 156, 390, 178),
    cg_node("dw_sep2", 245, 178, 290, 40, "DW Sep Conv  s=2  →  56×56×64", "Stride in depthwise layer for downsampling", "#e0f4f2","#008A82","#002C3C"),
    arr(390, 218, 390, 238),

    '<rect x="190" y="238" width="400" height="90" rx="8" fill="rgba(0,138,130,0.05)" stroke="#80cbc4" stroke-width="1.5" stroke-dasharray="5,3"/>',
    '<text x="200" y="252" font-size="9" font-weight="700" fill="#008A82">BACKBONE  × 11 DW Sep Conv blocks</text>',
    cg_node("dw_stack", 210, 258, 360, 60, "11× Depthwise Separable Conv Blocks", "64→128→128→256→256→512(×5)→1024   progressive downsampling to 7×7", "#c8e6c9","#1a9b6b","#003320"),

    arr(390, 338, 390, 360),
    cg_node("gap_mb",  285, 360, 210, 34, "Global Average Pool", "7×7×1024  →  1024", "#fff9c4","#f39c12","#e65100"),
    arr(390, 394, 390, 416),
    cg_node("fc_mb",   285, 416, 210, 34, "Linear  1024→1000  +  Softmax", "1M params  swappable for custom tasks", "#ffebee","#c0392b","#7f0000"),
    '</svg>'
  )

  # ── YOLOv8 Graph ─────────────────────────────────────────────────────────
  yolo_svg <- paste0(
    '<svg id="cg-svg-yolo" viewBox="0 0 780 500" xmlns="http://www.w3.org/2000/svg" style="font-family:Arial,sans-serif;background:#fafafa;width:100%;height:auto;display:none;">',
    defs_svg,
    '<text x="390" y="22" text-anchor="middle" font-size="13" font-weight="800" fill="#002C3C">YOLOv8 — Object Detection Computation Graph</text>',
    '<text x="390" y="38" text-anchor="middle" font-size="9.5" fill="#546e7a">11.2M params (nano) | Real-time detection | Anchor-free — click any node</text>',

    cg_node("input_yolo", 300, 52, 180, 36, "Input Image", "640×640×3  letterboxed", "#fff3e0","#e67e22","#bf360c"),
    arr(390, 88, 390, 110),

    # Backbone
    '<rect x="80" y="110" width="250" height="200" rx="8" fill="rgba(0,44,60,0.03)" stroke="#b2dfdb" stroke-width="1.5" stroke-dasharray="6,3"/>',
    '<text x="92" y="124" font-size="9" font-weight="700" fill="#546e7a">BACKBONE  CSP-DarkNet53</text>',
    cg_node("backbone", 100, 132, 210, 160, "CSP-DarkNet53", "P3:80×80  P4:40×40  P5:20×20", "#e0f4f2","#008A82","#002C3C"),

    # Feature pyramid arrows
    arr(310, 175, 370, 175),  # P3
    arr(310, 212, 370, 212),  # P4
    arr(310, 248, 370, 248),  # P5

    # Neck PANet
    '<rect x="370" y="110" width="220" height="210" rx="8" fill="rgba(41,128,185,0.05)" stroke="#90caf9" stroke-width="1.5" stroke-dasharray="6,3"/>',
    '<text x="382" y="124" font-size="9" font-weight="700" fill="#2980b9">NECK  PANet</text>',

    # P-levels in neck
    '<rect x="380" y="160" width="70" height="24" rx="4" fill="#e3f2fd" stroke="#2980b9" stroke-width="1.5"/>',
    '<text x="415" y="176" text-anchor="middle" font-size="8.5" font-weight="700" fill="#0d47a1">P3 80×80</text>',
    '<rect x="380" y="200" width="70" height="24" rx="4" fill="#e3f2fd" stroke="#2980b9" stroke-width="1.5"/>',
    '<text x="415" y="216" text-anchor="middle" font-size="8.5" font-weight="700" fill="#0d47a1">P4 40×40</text>',
    '<rect x="380" y="240" width="70" height="24" rx="4" fill="#e3f2fd" stroke="#2980b9" stroke-width="1.5"/>',
    '<text x="415" y="256" text-anchor="middle" font-size="8.5" font-weight="700" fill="#0d47a1">P5 20×20</text>',

    # FPN (top-down) arrows
    '<line x1="415" y1="240" x2="415" y2="224" stroke="#2980b9" stroke-width="1.5" marker-end="url(#cgArr)"/>',
    '<line x1="415" y1="200" x2="415" y2="184" stroke="#2980b9" stroke-width="1.5" marker-end="url(#cgArr)"/>',
    '<text x="420" y="215" font-size="7.5" fill="#2980b9">FPN</text>',
    '<text x="420" y="195" font-size="7.5" fill="#2980b9">top-down</text>',

    # PAN (bottom-up)
    cg_node("neck", 460, 160, 118, 114, "PANet Fused", "FPN + PAN  bidirectional", "#fff9c4","#f39c12","#7f5000"),
    '<text x="480" y="200" font-size="7.5" fill="#e65100" font-weight="700">FPN: top-down</text>',
    '<text x="480" y="212" font-size="7.5" fill="#e65100">semantic to small</text>',
    '<text x="480" y="228" font-size="7.5" fill="#27ae60" font-weight="700">PAN: bottom-up</text>',
    '<text x="480" y="240" font-size="7.5" fill="#27ae60">localise to large</text>',
    '<line x1="453" y1="172" x2="460" y2="172" stroke="#f39c12" stroke-width="1.5" marker-end="url(#cgArr)"/>',
    '<line x1="453" y1="212" x2="460" y2="212" stroke="#f39c12" stroke-width="1.5" marker-end="url(#cgArr)"/>',
    '<line x1="453" y1="248" x2="460" y2="248" stroke="#f39c12" stroke-width="1.5" marker-end="url(#cgArr)"/>',

    arr(578, 212, 618, 212),

    # Head
    '<rect x="618" y="110" width="140" height="210" rx="8" fill="rgba(192,57,43,0.05)" stroke="#f48fb1" stroke-width="1.5" stroke-dasharray="6,3"/>',
    '<text x="630" y="124" font-size="9" font-weight="700" fill="#c0392b">DETECTION HEAD</text>',
    cg_node("head",     628, 132, 120, 168, "Decoupled Head", "3 scales  anchor-free", "#ffebee","#c0392b","#7f0000"),
    '<text x="688" y="172" text-anchor="middle" font-size="8" fill="#c0392b" font-weight="700">Box branch</text>',
    '<text x="688" y="184" text-anchor="middle" font-size="8" fill="#c0392b">DFL: 4 values</text>',
    '<text x="688" y="202" text-anchor="middle" font-size="8" fill="#8e44ad" font-weight="700">Class branch</text>',
    '<text x="688" y="214" text-anchor="middle" font-size="8" fill="#8e44ad">num_classes</text>',
    '<text x="688" y="234" text-anchor="middle" font-size="8" fill="#546e7a">P3: 6400 anchors</text>',
    '<text x="688" y="246" text-anchor="middle" font-size="8" fill="#546e7a">P4: 1600 anchors</text>',
    '<text x="688" y="258" text-anchor="middle" font-size="8" fill="#546e7a">P5:  400 anchors</text>',
    '<text x="688" y="275" text-anchor="middle" font-size="7.5" fill="#546e7a">Total: 8400 predictions</text>',
    '<text x="688" y="290" text-anchor="middle" font-size="7.5" fill="#546e7a">before NMS</text>',

    arr(688, 320, 688, 358),
    cg_node("nms",      618, 358, 140, 40, "NMS  IoU=0.45", "Non-Maximum Suppression", "#e8eaf6","#5c6bc0","#1a237e"),

    # Output
    arr(688, 398, 688, 428),
    '<rect x="608" y="428" width="160" height="34" rx="6" fill="#e8f5e9" stroke="#27ae60" stroke-width="2"/>',
    '<text x="688" y="449" text-anchor="middle" font-size="10" font-weight="700" fill="#1b5e20">Final Detections</text>',
    '<text x="688" y="462" text-anchor="middle" font-size="8" fill="#2e7d32">boxes + scores + class_ids</text>',
    '</svg>'
  )

  # ── Compression data for interactive table ─────────────────────────────────
  tagList(
    tags$head(tags$style(HTML(css))),
    HTML(graph_js),

    div(class="meta-hero",
      tags$h1("Model Compression, Optimisation & Computation Graphs"),
      tags$h2("Chapter 7 deep dive — from architecture to edge deployment"),
      div(
        span(class="hero-badge","Quantisation"),
        span(class="hero-badge","Pruning"),
        span(class="hero-badge","Distillation"),
        span(class="hero-badge","LoRA"),
        span(class="hero-badge","Interactive Graphs")
      ),
      tags$p(style="color:rgba(255,255,255,0.7);font-size:12px;margin-top:10px;",
        "Click any node in the computation graphs to reveal layer-level implementation details, FLOPs, parameter counts, and compression strategies.")
    ),

    # ── Section 1: Interactive Computation Graphs ─────────────────────────
    fluidRow(
      box(title="🔬 Interactive Computation Graphs — Click Any Node",
          status="primary", solidHeader=TRUE, width=12,

        div(class="model-selector",
          tags$button(class="model-btn active", `data-model`="resnet",    onclick="cgSelectModel('resnet')",    "ResNet-50"),
          tags$button(class="model-btn",        `data-model`="bert",      onclick="cgSelectModel('bert')",      "BERT-base"),
          tags$button(class="model-btn",        `data-model`="gpt2",      onclick="cgSelectModel('gpt2')",      "GPT-2"),
          tags$button(class="model-btn",        `data-model`="mobilenet", onclick="cgSelectModel('mobilenet')", "MobileNet-V1"),
          tags$button(class="model-btn",        `data-model`="yolo",      onclick="cgSelectModel('yolo')",      "YOLOv8")
        ),
        div(class="cg-wrap",
          HTML(resnet_svg),
          HTML(bert_svg),
          HTML(gpt2_svg),
          HTML(mobilenet_svg),
          HTML(yolo_svg)
        ),
        div(id="cg-detail-panel", class="cg-detail")
      )
    ),

    # ── Section 2: Quantisation deep-dive ─────────────────────────────────
    fluidRow(
      box(title="🎯 Quantisation — Numerical Precision Reduction",
          status="warning", solidHeader=TRUE, width=7,

        tags$p(style="font-size:12.5px;color:#2c3e50;",
          "Quantisation maps floating-point weights and activations to lower-precision integer or reduced-float formats. The core trade-off: memory + speed vs accuracy."),
        br(),

        div(style="margin-bottom:16px;",
          span(class="prec-pill fp32","FP32  32-bit  full precision"),
          span(class="prec-pill fp16","FP16  16-bit  half precision"),
          span(class="prec-pill bf16","BF16  16-bit  brain float"),
          span(class="prec-pill int8","INT8  8-bit  integer"),
          span(class="prec-pill int4","INT4  4-bit  extreme")
        ),

        tags$table(class="comp-table",
          tags$thead(tags$tr(
            tags$th("Format"), tags$th("Bits"), tags$th("Size vs FP32"),
            tags$th("Accuracy Drop"), tags$th("Speedup (GPU)"), tags$th("Best For")
          )),
          tags$tbody(
            tags$tr(tags$td(tags$span(class="prec-pill fp32","FP32")), tags$td("32"), tags$td("1×"), tags$td("Baseline"), tags$td("1×"), tags$td("Training, research")),
            tags$tr(tags$td(tags$span(class="prec-pill fp16","FP16")), tags$td("16"), tags$td("2× smaller"), tags$td("< 0.1%"), tags$td("1.5–2×"), tags$td("Training (AMP), cloud serving")),
            tags$tr(tags$td(tags$span(class="prec-pill bf16","BF16")), tags$td("16"), tags$td("2× smaller"), tags$td("< 0.1%"), tags$td("1.5–2×"), tags$td("LLM training (better range than FP16)")),
            tags$tr(tags$td(tags$span(class="prec-pill int8","INT8")), tags$td("8"), tags$td("4× smaller"), tags$td("< 1%"), tags$td("2–4×"), tags$td("Edge, mobile, CPU serving")),
            tags$tr(tags$td(tags$span(class="prec-pill int4","INT4")), tags$td("4"), tags$td("8× smaller"), tags$td("1–3%"), tags$td("3–5×"), tags$td("LLM on consumer GPU (GPTQ, AWQ)"))
          )
        ),
        br(),
        div(class="tip-box",
          HTML("<strong>PTQ vs QAT:</strong> Post-Training Quantisation (PTQ) — apply after training, fast but ~1% drop. Quantisation-Aware Training (QAT) — simulate quantisation during training, recovers most accuracy loss. Use QAT when INT8 PTQ drops > 0.5% and task is accuracy-critical.")
        ),
        div(class="warn-box",
          HTML("<strong>LLM quantisation gotcha:</strong> Outlier activations in LLMs (particularly in attention layers) cause large PTQ errors. SmoothQuant migrates quantisation difficulty from activations to weights. GPTQ/AWQ use weight-only quantisation to preserve activation precision.")
        )
      ),

      box(title="📐 FLOPs vs Parameters — What Actually Limits Inference",
          status="info", solidHeader=TRUE, width=5,

        tags$p(style="font-size:12px;color:#546e7a;margin-bottom:12px;",
          "Parameters = memory footprint. FLOPs = compute. They are NOT proportional — understanding both is essential for deployment decisions."),

        tags$table(class="comp-table",
          tags$thead(tags$tr(
            tags$th("Model"), tags$th("Params"), tags$th("FLOPs"), tags$th("Top-1 %")
          )),
          tags$tbody(
            tags$tr(tags$td("ResNet-18"),   tags$td("11.7M"), tags$td("1.8B"),  tags$td("69.8")),
            tags$tr(tags$td("ResNet-50"),   tags$td("25.6M"), tags$td("4.1B"),  tags$td("76.1")),
            tags$tr(tags$td("ResNet-101"),  tags$td("44.5M"), tags$td("7.9B"),  tags$td("77.4")),
            tags$tr(tags$td("MobileNet-V1"),tags$td("4.2M"),  tags$td("569M"), tags$td("70.6")),
            tags$tr(tags$td("MobileNet-V2"),tags$td("3.4M"),  tags$td("300M"), tags$td("72.0")),
            tags$tr(tags$td("EfficientNet-B0"),tags$td("5.3M"),tags$td("390M"),tags$td("77.1")),
            tags$tr(tags$td("ViT-B/16"),    tags$td("86M"),   tags$td("17.6B"),tags$td("81.8")),
            tags$tr(tags$td("BERT-base"),   tags$td("110M"),  tags$td("22.5B/seq"), tags$td("—"))
          )
        ),
        br(),
        div(class="framework-card",
          tags$h5("Memory-bound vs Compute-bound"),
          tags$p("Small models on GPU are often memory-bound (GPU memory bandwidth < compute). Large batch sizes flip to compute-bound. Quantisation helps both: reduces model size (memory) and enables INT8 tensor cores (compute)."),
          tags$p(tags$b("Roofline model:"), " plot arithmetic intensity (FLOPs/byte) vs hardware limit. Ops below the roofline are memory-bound; above are compute-bound.")
        )
      )
    ),

    # ── Section 3: Compression Pipeline ───────────────────────────────────
    fluidRow(
      box(title="⚙️ Production Model Compression Pipeline",
          status="success", solidHeader=TRUE, width=6,

        div(class="cflow-step",
          div(class="cflow-num","1"),
          div(class="cflow-body",
            tags$h6("Profile the uncompressed model"),
            tags$p("Measure latency (p50/p95), memory, FLOPs on target hardware. Identify the bottleneck layer. torch.profiler, ONNX Runtime profiler, Netron for visualisation.")
          )
        ),
        div(class="cflow-step",
          div(class="cflow-num","2"),
          div(class="cflow-body",
            tags$h6("Try PTQ first  (Post-Training Quantisation)"),
            tags$p("INT8 PTQ with calibration data (128–512 samples). If accuracy drop < 0.5%: ship it. Tools: TensorRT, ONNX Runtime quant, torch.quantization. Cost: 1 hour.")
          )
        ),
        div(class="cflow-step",
          div(class="cflow-num","3"),
          div(class="cflow-body",
            tags$h6("If PTQ insufficient → Pruning + QAT"),
            tags$p("Structured pruning (remove filters): 30-50% sparsity with < 1% accuracy loss. Then QAT to recover accuracy. Requires retraining. Cost: 10-50% of original training time.")
          )
        ),
        div(class="cflow-step",
          div(class="cflow-num","4"),
          div(class="cflow-body",
            tags$h6("Distillation for maximum compression"),
            tags$p("Train smaller student on teacher soft labels. DistilBERT: 60% size, 97% performance. 2-3× longer training but student is permanently smaller.")
          )
        ),
        div(class="cflow-step",
          div(class="cflow-num","5"),
          div(class="cflow-body",
            tags$h6("Export to optimised runtime"),
            tags$p("Export to ONNX → TensorRT (NVIDIA GPU), CoreML (Apple), TFLite (Android/edge). Runtime-level optimisations: operator fusion, memory layout optimisation, kernel auto-tuning.")
          )
        ),
        div(class="success-box",
          HTML("<strong>Huyen's rule:</strong> 'Most production models are over-parameterised for serving. 10–100× compression with < 1% accuracy loss is routinely achievable. Always compress before claiming you need bigger hardware.'")
        )
      ),

      box(title="🔧 Distillation, LoRA & Advanced Techniques",
          status="danger", solidHeader=TRUE, width=6,

        div(class="framework-card",
          tags$h5("Knowledge Distillation — Teacher-Student"),
          tags$p(tags$b("Mechanism:"), " student minimises KL divergence between its softmax outputs and teacher's soft probabilities (temperature T > 1 to soften distributions). Soft labels carry inter-class similarity — richer signal than one-hot labels."),
          tags$p(tags$b("Loss:"), " L = α × L_CE(student, hard_labels) + (1-α) × T² × KL(student_soft || teacher_soft)"),
          tags$p(tags$b("Examples:"), " DistilBERT (6→66% of BERT-base), TinyBERT (4 layers), MobileNet from ResNet teacher, LLaMA-2 7B from 70B."),
          div(span(class="cg-tag","DistilBERT"), span(class="cg-tag blue","TinyBERT"), span(class="cg-tag orange","Temperature scaling"))
        ),

        div(class="framework-card",
          tags$h5("LoRA — Low-Rank Adaptation"),
          tags$p(tags$b("Core idea:"), " Weight update ΔW ≈ BA where B ∈ ℝ^(d×r), A ∈ ℝ^(r×k), rank r << min(d,k). For r=8, d=k=768: ΔW has 768² = 590K params, BA has 2×768×8 = 12K — 50× fewer trainable params."),
          tags$p(tags$b("At inference:"), " merge W ← W + BA. Zero latency overhead. Or keep separate for multi-LoRA serving: share base model, swap adapters per tenant."),
          tags$p(tags$b("QLoRA:"), " Quantise base model to 4-bit (NF4 format), train LoRA adapters in BF16. Fine-tune 70B LLM on single 48GB GPU."),
          div(span(class="cg-tag","r=8 typical"), span(class="cg-tag blue","α=16 scaling"), span(class="cg-tag orange","QLoRA 4-bit"))
        ),

        div(class="framework-card",
          tags$h5("Operator Fusion & Graph Optimisation"),
          tags$p("TensorRT / XLA / torch.compile fuse sequences of ops into single kernels:"),
          tags$ul(
            tags$li(tags$b("Conv-BN fusion:"), " fold BatchNorm into Conv weights at inference. Eliminates BN as a separate op."),
            tags$li(tags$b("Flash Attention:"), " fuse Q×K, softmax, ×V into tiled SRAM ops. 2-4× faster, 10× less memory. Critical for long-context LLMs."),
            tags$li(tags$b("Kernel auto-tuning:"), " TVM/Triton search over tiling, unrolling, vectorisation strategies for each op shape.")
          ),
          div(span(class="cg-tag","BN Fusion"), span(class="cg-tag blue","Flash Attention"), span(class="cg-tag orange","torch.compile"))
        )
      )
    ),

    # ── Section 4: Serving Frameworks ─────────────────────────────────────
    fluidRow(
      box(title="🚀 Serving Frameworks — From Model to Production",
          status="primary", solidHeader=TRUE, width=12,

        tags$table(class="comp-table",
          tags$thead(tags$tr(
            tags$th("Framework"), tags$th("Best For"), tags$th("Key Feature"),
            tags$th("Quantisation"), tags$th("Batching"), tags$th("Interview Mention When")
          )),
          tags$tbody(
            tags$tr(tags$td(tags$b("TensorRT")),       tags$td("NVIDIA GPU"),     tags$td("INT8/FP16 kernel fusion, auto-tune"),     tags$td("INT8, FP16, FP8"),  tags$td("Dynamic"), tags$td("Low-latency NVIDIA GPU serving")),
            tags$tr(tags$td(tags$b("ONNX Runtime")),   tags$td("Cross-platform"), tags$td("Op fusion, graph optimisation"),          tags$td("INT8, FP16"),       tags$td("Static"),  tags$td("Portability across hardware")),
            tags$tr(tags$td(tags$b("TorchServe")),     tags$td("PyTorch models"), tags$td("Model versioning, A/B routing"),          tags$td("Via TensorRT"),     tags$td("Dynamic"), tags$td("PyTorch native serving")),
            tags$tr(tags$td(tags$b("Triton")),         tags$td("Multi-model GPU"),tags$td("GPU memory sharing, concurrent models"),  tags$td("All formats"),      tags$td("Dynamic"), tags$td("Multi-model / multi-tenant serving")),
            tags$tr(tags$td(tags$b("vLLM")),           tags$td("LLM serving"),    tags$td("PagedAttention: virtual KV-cache pages"), tags$td("GPTQ, AWQ, FP8"),  tags$td("Continuous"),tags$td("Any LLM production deployment")),
            tags$tr(tags$td(tags$b("TFLite")),         tags$td("Mobile/Edge"),    tags$td("XNNPACK delegate, CoreML delegate"),      tags$td("INT8, FP16"),       tags$td("Static"),  tags$td("Android/iOS edge deployment")),
            tags$tr(tags$td(tags$b("CoreML")),         tags$td("Apple Silicon"),  tags$td("ANE (Neural Engine) acceleration"),       tags$td("INT8, FP16"),       tags$td("Static"),  tags$td("Apple device on-device inference"))
          )
        ),
        br(),
        div(class="info-box-plain",
          HTML("<strong>vLLM PagedAttention:</strong> KV cache grows with sequence length and becomes the bottleneck for LLM serving throughput. PagedAttention treats KV cache as virtual memory pages — non-contiguous allocation, no internal fragmentation. Combined with continuous batching (process tokens as they arrive), vLLM achieves 30× throughput improvement over naive HuggingFace serving.")
        )
      )
    ),

    # ── Self-Assessment ────────────────────────────────────────────────────
    fluidRow(
      box(title="📊 Self-Assessment: Model Compression & Optimisation",
          status="success", solidHeader=TRUE, width=12,
        fluidRow(
          column(4,
            sliderInput(ns("sc_quant"),   "Quantisation (PTQ/QAT)",   0, 10, 5),
            sliderInput(ns("sc_prune"),   "Pruning strategies",        0, 10, 5),
            sliderInput(ns("sc_distil"),  "Knowledge distillation",    0, 10, 5),
            sliderInput(ns("sc_lora"),    "LoRA / parameter-efficient",0, 10, 5),
            sliderInput(ns("sc_graphs"),  "Computation graph literacy",0, 10, 5),
            actionButton(ns("save_mc"), "Save Assessment", class="btn-meta", width="100%")
          ),
          column(8, br(), uiOutput(ns("mc_result")))
        )
      )
    )
  )
}

model_compression_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_mc, {
      avg <- mean(c(input$sc_quant, input$sc_prune, input$sc_distil, input$sc_lora, input$sc_graphs))
      pct <- round(avg * 10)
      prep_manager$update_progress("model_compression", pct)
      output$mc_result <- renderUI({
        col <- progress_colour(pct)
        div(class=if(pct>=70)"success-box"else"tip-box",
          tags$h3(style=paste0("color:",col), paste0(pct,"% ready")),
          if(pct>=80)
            tags$p("Strong compression knowledge. In interviews: always propose quantisation before requesting more hardware. Mention vLLM for LLM serving, TensorRT for GPU-bound CV models.")
          else
            tags$p("Review: INT8 PTQ workflow, distillation loss function, LoRA rank selection, and when to use vLLM vs TorchServe.")
        )
      })
      showNotification(paste0("Model Compression: ",pct,"% saved"), type="message")
    })
  })
}
