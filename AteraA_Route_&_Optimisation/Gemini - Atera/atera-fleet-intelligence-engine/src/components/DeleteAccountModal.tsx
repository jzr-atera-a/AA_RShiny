import React, { useState, useEffect } from 'react';
import { 
  X, 
  Trash2, 
  AlertTriangle, 
  ShieldAlert, 
  CheckCircle2, 
  RefreshCw, 
  Lock,
  ShieldCheck,
  CheckSquare,
  Square
} from 'lucide-react';

interface DeleteAccountModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirmWipe: () => void;
}

const REQUIRED_CONFIRMATION_TEXT = 'CONFIRM-PERMANENT-WIPE';

export const DeleteAccountModal: React.FC<DeleteAccountModalProps> = ({
  isOpen,
  onClose,
  onConfirmWipe,
}) => {
  const [typedConfirmation, setTypedConfirmation] = useState<string>('');
  const [ackVehicles, setAckVehicles] = useState<boolean>(false);
  const [ackRoutes, setAckRoutes] = useState<boolean>(false);
  const [countdown, setCountdown] = useState<number>(3);
  const [wiping, setWiping] = useState<boolean>(false);
  const [wipedSuccess, setWipedSuccess] = useState<boolean>(false);
  const [auditId, setAuditId] = useState<string>('');

  // Reset state and run safety interlock countdown when opened
  useEffect(() => {
    if (isOpen) {
      setTypedConfirmation('');
      setAckVehicles(false);
      setAckRoutes(false);
      setWiping(false);
      setWipedSuccess(false);
      setCountdown(3);

      const timer = setInterval(() => {
        setCountdown((prev) => {
          if (prev <= 1) {
            clearInterval(timer);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);

      return () => clearInterval(timer);
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const isTextMatched = typedConfirmation.trim() === REQUIRED_CONFIRMATION_TEXT;
  const isSafetyTimerUnlocked = countdown === 0;
  const isAllGuardsPassed = isTextMatched && ackVehicles && ackRoutes && isSafetyTimerUnlocked;

  const handleExecuteWipe = () => {
    if (!isAllGuardsPassed) return;

    setWiping(true);
    const certId = `ERA-2026-GDPR-${Math.floor(100000 + Math.random() * 900000)}`;
    setAuditId(certId);

    setTimeout(() => {
      // Clear client storage safely
      try {
        localStorage.clear();
        sessionStorage.clear();
      } catch (e) {
        // Safe fallback
      }

      onConfirmWipe();
      setWiping(false);
      setWipedSuccess(true);
    }, 1000);
  };

  return (
    <div 
      role="dialog" 
      aria-modal="true" 
      aria-labelledby="delete-account-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/85 backdrop-blur-md overflow-y-auto"
    >
      <div 
        className="bg-[#181B20] border-2 border-rose-500 rounded-2xl w-full max-w-lg shadow-2xl overflow-hidden flex flex-col my-auto max-h-[95vh]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header with Guard Shield */}
        <div className="px-6 py-4 border-b-2 border-rose-900/50 bg-[#26161B] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-rose-500/20 border border-rose-500/50 text-rose-400">
              <ShieldAlert className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 id="delete-account-title" className="text-base font-bold text-white uppercase tracking-wider">
                  Guarded Account Deletion & Data Wipe
                </h2>
                <span className="bg-rose-950 text-rose-300 border border-rose-800 text-[10px] font-mono-data px-1.5 py-0.5 rounded font-bold">
                  TRIPLE-GUARD
                </span>
              </div>
              <span className="text-[10px] font-mono-data text-rose-400 font-bold">
                GDPR ARTICLE 17 • STATUTORY RIGHT TO ERASURE
              </span>
            </div>
          </div>
          <button
            onClick={onClose}
            aria-label="Close delete account modal"
            className="p-1.5 rounded-lg bg-[#242932] hover:bg-[#2C323D] text-[#8C93A0] hover:text-white border border-[#393E46] transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 space-y-4 overflow-y-auto">
          {!wipedSuccess ? (
            <>
              {/* Warning Notice */}
              <div className="bg-[#1F1418] border border-rose-900/80 rounded-xl p-3.5 flex items-start gap-3">
                <AlertTriangle className="w-5 h-5 text-rose-400 shrink-0 mt-0.5" />
                <div className="space-y-1 text-xs">
                  <span className="font-bold text-white block">
                    Destructive Action Protected by Safeguards
                  </span>
                  <p className="text-[#C5CDD9] leading-relaxed">
                    To prevent accidental fleet data loss, this destructive erasure action requires explicit two-step typed confirmation and acknowledgement of unrecoverable data loss.
                  </p>
                </div>
              </div>

              {/* Data Scope slatted for purge */}
              <div className="bg-[#121417] border border-[#2A2E35] rounded-xl p-3 space-y-1.5 text-xs">
                <span className="text-[10px] uppercase font-mono-data text-[#8C93A0] tracking-wider block font-bold">
                  Data Slated for Irreversible Purge:
                </span>
                <ul className="space-y-1 text-[11px] text-[#A3ADC0]">
                  <li className="flex items-center gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-rose-500"></span>
                    <span>10,000+ commercial vehicle GPS telemetry records & CAN-bus state cache</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-rose-500"></span>
                    <span>Active Zone B storm bypass routes & emergency dispatch queues</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-rose-500"></span>
                    <span>Depot charging schedules, tariff models & operator session keys</span>
                  </li>
                </ul>
              </div>

              {/* Guard 1 & 2: Explicit Checkbox Acknowledgments */}
              <div className="space-y-2 pt-1 text-xs">
                <span className="text-[10px] uppercase font-mono-data text-[#8C93A0] font-bold block">
                  Step 1: Acknowledge Data Loss
                </span>

                <label 
                  className="flex items-start gap-2.5 p-2.5 rounded-lg bg-[#15181E] border border-[#2A2E35] hover:border-[#3E4552] cursor-pointer transition-colors"
                >
                  <input
                    type="checkbox"
                    checked={ackVehicles}
                    onChange={(e) => setAckVehicles(e.target.checked)}
                    className="sr-only"
                  />
                  {ackVehicles ? (
                    <CheckSquare className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                  ) : (
                    <Square className="w-4 h-4 text-[#8C93A0] shrink-0 mt-0.5" />
                  )}
                  <span className="text-[#C5CDD9] text-[11px] select-none">
                    I confirm that all 10,000+ vehicle assets, CAN-bus logs, and driver rosters will be permanently destroyed.
                  </span>
                </label>

                <label 
                  className="flex items-start gap-2.5 p-2.5 rounded-lg bg-[#15181E] border border-[#2A2E35] hover:border-[#3E4552] cursor-pointer transition-colors"
                >
                  <input
                    type="checkbox"
                    checked={ackRoutes}
                    onChange={(e) => setAckRoutes(e.target.checked)}
                    className="sr-only"
                  />
                  {ackRoutes ? (
                    <CheckSquare className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                  ) : (
                    <Square className="w-4 h-4 text-[#8C93A0] shrink-0 mt-0.5" />
                  )}
                  <span className="text-[#C5CDD9] text-[11px] select-none">
                    I understand active dispatch routes and storm overrides cannot be recovered once wiped.
                  </span>
                </label>
              </div>

              {/* Guard 3: Typed Confirmation */}
              <div className="space-y-1.5 pt-1 text-xs">
                <div className="flex items-center justify-between">
                  <label htmlFor="input-wipe-confirmation" className="text-[10px] uppercase font-mono-data text-[#8C93A0] font-bold">
                    Step 2: Type <span className="text-rose-400 font-bold">CONFIRM-PERMANENT-WIPE</span> below
                  </label>
                  {isTextMatched ? (
                    <span className="text-[10px] font-mono-data text-emerald-400 flex items-center gap-1 font-bold">
                      <ShieldCheck className="w-3 h-3" /> MATCHED
                    </span>
                  ) : (
                    <span className="text-[10px] font-mono-data text-[#8C93A0]">
                      Required
                    </span>
                  )}
                </div>

                <input
                  id="input-wipe-confirmation"
                  type="text"
                  value={typedConfirmation}
                  onChange={(e) => setTypedConfirmation(e.target.value)}
                  placeholder="CONFIRM-PERMANENT-WIPE"
                  autoComplete="off"
                  className={`w-full bg-[#121417] border-2 rounded-lg px-3 py-2 text-white font-mono-data text-xs focus:outline-none transition-colors ${
                    typedConfirmation.length > 0
                      ? isTextMatched
                        ? 'border-emerald-500 bg-emerald-950/20'
                        : 'border-rose-600 bg-rose-950/20'
                      : 'border-[#3A404D]'
                  }`}
                />
              </div>

              {/* Safety Interlock Timer Notice */}
              {!isSafetyTimerUnlocked && (
                <div className="p-2 bg-[#1B1E24] border border-[#2E3540] rounded-lg flex items-center justify-between text-[11px] font-mono-data text-amber-400">
                  <span className="flex items-center gap-1.5">
                    <Lock className="w-3.5 h-3.5" />
                    Safety Interlock Lockout Active:
                  </span>
                  <span className="font-bold">{countdown}s remaining</span>
                </div>
              )}

              {/* Guarded Action Button */}
              <div className="pt-2">
                <button
                  id="btn-confirm-1-click-wipe"
                  onClick={handleExecuteWipe}
                  disabled={!isAllGuardsPassed || wiping}
                  className={`w-full font-bold text-xs uppercase tracking-wider py-3 px-4 rounded-xl flex items-center justify-center gap-2 border-2 transition-all ${
                    isAllGuardsPassed && !wiping
                      ? 'bg-rose-600 hover:bg-rose-700 text-white border-rose-400 shadow-lg shadow-rose-600/30 cursor-pointer active:scale-[0.99]'
                      : 'bg-[#1F232B] text-[#6B7280] border-[#2A2E35] cursor-not-allowed opacity-60'
                  }`}
                >
                  {wiping ? (
                    <>
                      <RefreshCw className="w-4 h-4 animate-spin" />
                      <span>Executing Cryptographic Erasure...</span>
                    </>
                  ) : !isSafetyTimerUnlocked ? (
                    <>
                      <Lock className="w-4 h-4" />
                      <span>Safety Interlock Active ({countdown}s)...</span>
                    </>
                  ) : !isAllGuardsPassed ? (
                    <>
                      <Lock className="w-4 h-4" />
                      <span>Locked: Complete Steps 1 & 2 to Enable</span>
                    </>
                  ) : (
                    <>
                      <Trash2 className="w-4 h-4" />
                      <span>Authorize Permanent Erasure</span>
                    </>
                  )}
                </button>
              </div>
            </>
          ) : (
            /* Post-Wipe Confirmation */
            <div className="space-y-4 py-2 text-center">
              <div className="w-12 h-12 rounded-full bg-emerald-950/80 border-2 border-emerald-500 text-emerald-400 flex items-center justify-center mx-auto">
                <CheckCircle2 className="w-6 h-6" />
              </div>
              <div className="space-y-1">
                <h3 className="text-base font-bold text-white">
                  Account & Telematics Successfully Wiped
                </h3>
                <p className="text-xs text-[#8C93A0]">
                  All user data, dispatch states, and cached vehicles have been securely erased.
                </p>
              </div>

              <div className="bg-[#121417] p-3 rounded-lg border border-[#2A2E35] text-left text-xs font-mono-data space-y-1">
                <div className="text-[10px] text-[#8C93A0]">ERASURE AUDIT CERTIFICATE:</div>
                <div className="text-emerald-400 font-bold">{auditId}</div>
                <div className="text-[10px] text-[#6B7280]">Status: PERMANENTLY PURGED (GDPR Compliant)</div>
              </div>

              <button
                onClick={onClose}
                className="w-full bg-[#242932] hover:bg-[#2E3540] text-white border-2 border-[#3A404D] font-bold text-xs uppercase tracking-wider py-2.5 px-4 rounded-lg transition-colors cursor-pointer"
              >
                Return to Nominal Baseline
              </button>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-3 border-t-2 border-[#2A2E35] bg-[#14171C] flex items-center justify-between text-[11px] text-[#8C93A0]">
          <span className="flex items-center gap-1.5">
            <Lock className="w-3.5 h-3.5 text-[#00ADB5]" />
            <span>Cryptographic Zero-Knowledge Scrubbing</span>
          </span>
          <button
            onClick={onClose}
            className="text-[#9CA3AF] hover:text-white transition-colors cursor-pointer"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
};
