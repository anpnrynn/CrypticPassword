import com.anoop.crypticpassword.CrypticPasswordAlgorithm;

public final class CrypticPasswordAlgorithmSmoke {
    public static void main(String[] args) {
        for (CrypticPasswordAlgorithm.Version version : CrypticPasswordAlgorithm.Version.values()) {
            String s = CrypticPasswordAlgorithm.shuffle(version, 2023);
            if (s.length() != CrypticPasswordAlgorithm.TOTAL_CELLS) {
                throw new IllegalStateException(version.label + " length=" + s.length());
            }
            System.out.println("PASS " + version.label + " " + s.substring(0, 12));
        }
        System.out.println("ANDROID_JAVA_CORE_PASS_ALL_ALGORITHMS");
    }
}
