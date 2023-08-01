using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InteractiveGrassEffects : MonoBehaviour
{
    [SerializeField]
    MeshRenderer grassRenderer;

    void Awake()
    {
        Material mat = grassRenderer.material;

        Camera cam = GetComponent<Camera>();
        mat.SetTexture("_EffectRT", cam.targetTexture);
        mat.SetFloat("_OrthographicCamSize", cam.orthographicSize);
        mat.SetVector("_CamPos", transform.position);
    }
}
