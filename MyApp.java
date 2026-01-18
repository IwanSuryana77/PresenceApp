public class MyApp extends Application {
    @Override
    public void onCreate() {
        super.onCreate();

        Map<String, Object> config = new HashMap<>();
        config.put("cloud_name", "facesign123"); // ganti dengan punyamu

        MediaManager.init(this, config);
    }
}
