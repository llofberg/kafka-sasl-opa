package io.lbg.kafka.opa;

import com.google.gson.Gson;
import lombok.Cleanup;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.CommonClientConfigs;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.common.config.SslConfigs;
import org.apache.kafka.common.serialization.LongDeserializer;
import org.apache.kafka.common.serialization.StringDeserializer;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Collections;
import java.util.Map;
import java.util.Properties;

@Slf4j
public class KafkaOpaConsumer {

  private final static String TOPIC = "X";
  private final static String BOOTSTRAP_SERVERS = "broker:9093";
  private static final String OPA_URL = "http://opa:8181/v1/data/kafka/message/allow";
  private boolean keepRunning = true;

  public static void main(String[] args) {
    new KafkaOpaConsumer().run();
  }

  private void run() {

    final Properties props = new Properties();
    props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVERS);
    props.put(ConsumerConfig.GROUP_ID_CONFIG, "ssl-sasl-host");
    props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, LongDeserializer.class.getName());
    props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());

    props.put(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");

    props.put(SslConfigs.SSL_TRUSTSTORE_LOCATION_CONFIG, "/etc/kafka/secrets/kafka.consumer.truststore.jks");
    props.put(SslConfigs.SSL_TRUSTSTORE_PASSWORD_CONFIG, "confluent");
    props.put(SslConfigs.SSL_KEYSTORE_LOCATION_CONFIG, "/etc/kafka/secrets/kafka.consumer.keystore.jks");
    props.put(SslConfigs.SSL_KEYSTORE_PASSWORD_CONFIG, "confluent");
    props.put(SslConfigs.SSL_KEY_PASSWORD_CONFIG, "confluent");

    props.put(SaslConfigs.SASL_MECHANISM, "GSSAPI");
    props.put(SaslConfigs.SASL_KERBEROS_SERVICE_NAME, "kafka");

    while (keepRunning) {
      try {
        @Cleanup final Consumer<Long, String> consumer = new KafkaConsumer<>(props);
        consumer.subscribe(Collections.singletonList(TOPIC));
        while (keepRunning) {
          final ConsumerRecords<Long, String> consumerRecords = consumer.poll(10000);
          consumerRecords.forEach(record -> log.debug("{} => {}", record, allow(record.value())));
          consumer.commitAsync();
        }
      } catch (Exception ignored) {
        try {
          Thread.sleep(2000);
        } catch (InterruptedException ignored2) {
        }
      }
    }
  }

  private Gson gson = new Gson();

  private boolean allow(String input) {
    try {
      HttpURLConnection conn = (HttpURLConnection)
        new URL(OPA_URL).openConnection();

      conn.setDoOutput(true);
      conn.setRequestMethod("POST");
      conn.setRequestProperty("Content-Type", "application/json");

      OutputStream os = conn.getOutputStream();
      os.write(("{\"input\":" + input + "}").getBytes());
      os.flush();

      @Cleanup BufferedReader br = new BufferedReader(new InputStreamReader((conn.getInputStream())));
      String json = br.readLine();

      Map map = gson.fromJson(json, Map.class);
      return map.containsKey("result") && (boolean) map.get("result");
    } catch (IOException e) {
      return false;
    }
  }
}
