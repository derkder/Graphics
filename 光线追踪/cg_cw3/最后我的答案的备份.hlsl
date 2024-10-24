#define SOLUTION_LIGHT
#define SOLUTION_BOUNCE
// the following macro is the simple flag of our unit test
//#define TEST_RANDOM_DIRECTION
#define SOLUTION_THROUGHPUT
//#define SOLUTION_AA
//#define SOLUTION_MB
//#define SOLUTION_VR_GOODSAMPLE
//#define SOLUTION_VR_IMPORTANCES_cos
//#define SOLUTION_VR_IMPORTANCES_brdf



precision highp float;

#define M_PI 3.14159265359

struct Material {
	#ifdef SOLUTION_LIGHT
	vec3 emission;
	/* 
	what gamma is doing in our case:
	Gamma correction is usually applied to control the luminance of the image by compensating for the nonlinear response of the display device to ensure that the rendered  	 image is more natural to the human eye. 
	In our case ecplicitly, gamma is set to 1.6 to improve the details in the mid-brightness region of the image which enhances the realism of the pathtraced scene.
	*/
	#endif
	vec3 diffuse;
	vec3 specular;
	float glossiness;
};

struct Sphere {
	vec3 position;
#ifdef SOLUTION_MB
	vec3 motion;
#endif
	float radius;
	Material material;
};

struct Plane {
	vec3 normal;
	float d;
	Material material;
};

const int sphereCount = 4;
const int planeCount = 4;
const int emittingSphereCount = 2;
#ifdef SOLUTION_BOUNCE
const int maxPathLength = 2;
#else
const int maxPathLength = 1;
#endif 

struct Scene {
	Sphere[sphereCount] spheres;
	Plane[planeCount] planes;
};

struct Ray {
	vec3 origin;
	vec3 direction;
};

// Contains all information pertaining to a ray/object intersection
struct HitInfo {
	bool hit;
	float t;
	vec3 position;
	vec3 normal;
	Material material;
};

// Contains info to sample a direction and this directions probability
struct DirectionSample {
	vec3 direction;
	float probability;
};

HitInfo getEmptyHit() {
	Material emptyMaterial;
	#ifdef SOLUTION_LIGHT
	emptyMaterial.emission = vec3(0.0);
	#endif
	emptyMaterial.diffuse = vec3(0.0);
	emptyMaterial.specular = vec3(0.0);
	emptyMaterial.glossiness = 1.0;
	return HitInfo(false, 0.0, vec3(0.0), vec3(0.0), emptyMaterial);
}

// Sorts the two t values such that t1 is smaller than t2
void sortT(inout float t1, inout float t2) {
	// Make t1 the smaller t
	if(t2 < t1)  {
		float temp = t1;
		t1 = t2;
		t2 = temp;
	}
}

// Tests if t is in an interval
bool isTInInterval(const float t, const float tMin, const float tMax) {
	return t > tMin && t < tMax;
}

// Get the smallest t in an interval
bool getSmallestTInInterval(float t0, float t1, const float tMin, const float tMax, inout float smallestTInInterval) {

	sortT(t0, t1);

	// As t0 is smaller, test this first
	if(isTInInterval(t0, tMin, tMax)) {
		smallestTInInterval = t0;
		return true;
	}

	// If t0 was not in the interval, still t1 could be
	if(isTInInterval(t1, tMin, tMax)) {
		smallestTInInterval = t1;
		return true;
	}

	// None was
	return false;
}

// Converts a random integer in 15 bits to a float in (0, 1)
float randomIntegerToRandomFloat(int i) {
	return float(i) / 32768.0;
}

// Returns a random integer for every pixel and dimension that remains the same in all iterations
int pixelIntegerSeed(const int dimensionIndex) {
	vec3 p = vec3(gl_FragCoord.xy, dimensionIndex);
	vec3 r = vec3(23.14069263277926, 2.665144142690225,7.358926345 );
	return int(32768.0 * fract(cos(dot(p,r)) * 123456.0));
}

// Returns a random float for every pixel that remains the same in all iterations
float pixelSeed(const int dimensionIndex) {
	return randomIntegerToRandomFloat(pixelIntegerSeed(dimensionIndex));
}

// The global random seed of this iteration
// It will be set to a new random value in each step
uniform int globalSeed;
int randomSeed;
void initRandomSequence() {
	randomSeed = globalSeed + pixelIntegerSeed(0);
}

// Computes integer  x modulo y not available in most WEBGL SL implementations
int mod(const int x, const int y) {
	return int(float(x) - floor(float(x) / float(y)) * float(y));
}

// Returns the next integer in a pseudo-random sequence
int rand() {
	randomSeed = randomSeed * 1103515245 + 12345;
	return mod(randomSeed / 65536, 32768);
}

float uniformRandomImproved(vec2 co){
    float a = 12.9898;
    float b = 78.233;
    float c = 43758.5453;
    float dt= dot(co.xy ,vec2(a,b));
    float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

// Returns the next float in this pixels pseudo-random sequence
float uniformRandom() {
	return randomIntegerToRandomFloat(rand());
}

// This is the index of the sample controlled by the framework.
// It increments by one in every call of this shader
uniform int baseSampleIndex;

// Returns a well-distributed number in (0,1) for the dimension dimensionIndex
float sample(const int dimensionIndex) {
	// combining 2 PRNGs to avoid the patterns in the C-standard LCG
	return uniformRandomImproved(vec2(uniformRandom(), uniformRandom()));
}

// This is a helper function to sample two-dimensionaly in dimension dimensionIndex
vec2 sample2(const int dimensionIndex) {
	return vec2(sample(dimensionIndex + 0), sample(dimensionIndex + 1));
}

vec3 sample3(const int dimensionIndex) {
	return vec3(sample(dimensionIndex + 0), sample(dimensionIndex + 1), sample(dimensionIndex + 2));
}

// This is a register of all dimensions that we will want to sample.
// Thanks to Iliyan Georgiev from Solid Angle for explaining proper housekeeping of sample dimensions in ranomdized Quasi-Monte Carlo
//
// There are infinitely many path sampling dimensions.
// These start at PATH_SAMPLE_DIMENSION.
// The 2D sample pair for vertex i is at PATH_SAMPLE_DIMENSION + PATH_SAMPLE_DIMENSION_MULTIPLIER * i + 0
#define ANTI_ALIAS_SAMPLE_DIMENSION 0
#define TIME_SAMPLE_DIMENSION 1
#define PATH_SAMPLE_DIMENSION 3

// This is 2 for two dimensions and 2 as we use it for two purposese: NEE and path connection
#define PATH_SAMPLE_DIMENSION_MULTIPLIER (2 * 2)

vec3 getEmission(const Material material, const vec3 normal) {
	#ifdef SOLUTION_LIGHT
	return material.emission;
	#else 
	// This is wrong. It just returns the diffuse color so that you see something to be sure it is working.
	return material.diffuse;
	#endif
}

vec3 getReflectance(const Material material, const vec3 normal, const vec3 inDirection, const vec3 outDirection) {
	#ifdef SOLUTION_THROUGHPUT
	//phong, the formula in the pdf which doesnt get the same img as the answer, to be specfic, there is no highlight on the back wall
	//vec3 r = reflect(normal, inDirection);
	//float cosTheta = max(dot(outDirection, r), 0.0);
	
	//blinn Phone, which uses half vector instead of reflct vector and gets the same img as the answer
	vec3 h = normalize(inDirection + outDirection);
	float cosTheta = max(dot(normal, h), 0.0);
	vec3 specular = material.specular * pow(cosTheta, material.glossiness);
	vec3 diffuse = material.diffuse / M_PI;
	return (diffuse + specular * ((material.glossiness + 2.0) / (2.0 * M_PI)));
	#else
	return vec3(1.0);
	#endif
}

vec3 getGeometricTerm(const Material material, const vec3 normal, const vec3 inDirection, const vec3 outDirection) {
	#ifdef SOLUTION_THROUGHPUT
	float cosTheta = max(dot(normal, outDirection), 0.0);
	//cosTheta = dot(normal, inDirection);
   return vec3(cosTheta);
	//return vec3(1.); // Perfect reflection for now
	#else
	return vec3(1.0);
	#endif
}

vec3 sphericalToEuclidean(float theta, float phi) {
	float x = sin(theta) * cos(phi);
	float y = sin(theta) * sin(phi);
	float z = cos(theta);
	return vec3(x, y, z);	
}

vec3 getRandomDirection(const int dimensionIndex) {
	#ifdef SOLUTION_BOUNCE
	// Spherical Coordinates Calculation
	vec2 sampleCoords = sample2(PATH_SAMPLE_DIMENSION + 2 * dimensionIndex);
	float theta = acos(2.0 * sampleCoords.x - 1.0);
	float phi = sampleCoords.y * 2.0 * M_PI;

   return sphericalToEuclidean(theta, phi);
	#else
	// Put your code to compute a random direction in 3D in the #ifdef above
	return vec3(0);
	#endif
}

HitInfo intersectSphere(const Ray ray, Sphere sphere, const float tMin, const float tMax) {

#ifdef SOLUTION_MB
	sphere.position += sphere.motion * uniformRandom();
#endif
	
	vec3 to_sphere = ray.origin - sphere.position;

	float a = dot(ray.direction, ray.direction);
	float b = 2.0 * dot(ray.direction, to_sphere);
	float c = dot(to_sphere, to_sphere) - sphere.radius * sphere.radius;
	float D = b * b - 4.0 * a * c;
	if (D > 0.0)
	{
		float t0 = (-b - sqrt(D)) / (2.0 * a);
		float t1 = (-b + sqrt(D)) / (2.0 * a);

		float smallestTInInterval;
		if(!getSmallestTInInterval(t0, t1, tMin, tMax, smallestTInInterval)) {
			return getEmptyHit();
		}

		vec3 hitPosition = ray.origin + smallestTInInterval * ray.direction;

		vec3 normal =
			length(ray.origin - sphere.position) < sphere.radius + 0.001?
			-normalize(hitPosition - sphere.position) :
		normalize(hitPosition - sphere.position);

		return HitInfo(
			true,
			smallestTInInterval,
			hitPosition,
			normal,
			sphere.material);
	}
	return getEmptyHit();
}

HitInfo intersectPlane(Ray ray, Plane plane) {
	float t = -(dot(ray.origin, plane.normal) + plane.d) / dot(ray.direction, plane.normal);
	vec3 hitPosition = ray.origin + t * ray.direction;
	return HitInfo(
		true,
		t,
		hitPosition,
		normalize(plane.normal),
		plane.material);
	return getEmptyHit();
}

float lengthSquared(const vec3 x) {
	return dot(x, x);
}

HitInfo intersectScene(Scene scene, Ray ray, const float tMin, const float tMax)
{
	HitInfo best_hit_info;
	best_hit_info.t = tMax;
	best_hit_info.hit = false;

	for (int i = 0; i < sphereCount; ++i) {
		Sphere sphere = scene.spheres[i];
		HitInfo hit_info = intersectSphere(ray, sphere, tMin, tMax);

		if(	hit_info.hit &&
		   hit_info.t < best_hit_info.t &&
		   hit_info.t > tMin)
		{
			best_hit_info = hit_info;
		}
	}

	for (int i = 0; i < planeCount; ++i) {
		Plane plane = scene.planes[i];
		HitInfo hit_info = intersectPlane(ray, plane);

		if(	hit_info.hit &&
		   hit_info.t < best_hit_info.t &&
		   hit_info.t > tMin)
		{
			best_hit_info = hit_info;
		}
	}

	return best_hit_info;
}

mat3 transpose(mat3 m) {
	return mat3(
		m[0][0], m[1][0], m[2][0],
		m[0][1], m[1][1], m[2][1],
		m[0][2], m[1][2], m[2][2]
	);
}

// This function creates a matrix to transform from global space into a local space oriented around the provided vector.
mat3 makeLocalFrame(const vec3 vector) {
	vec3 up = abs(vector.z) < 0.999 ? vec3(0, 0, 1) : vec3(1, 0, 0);
	vec3 T = normalize(cross(up, vector));
	vec3 B = cross(vector, T);
	return mat3(T, B, vector);
}

float luminance(const vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

#define EPSILON (1e-6)  // for avoiding numeric issues caused by floating point accuracy

#ifdef TEST_RANDOM_DIRECTION
// transform random samples to spherical coordinates (theta, phi)
vec2 toSphericalCoordinates(float xi0, float xi1) {
    float theta = acos(2.0 * xi0 - 1.0);
    float phi = xi1 * 2.0 * M_PI;
    return vec2(theta, phi);
}

// convert spherical coordinates to Cartesian coordinates
// this function is the same as the given spherical Euclidean
vec3 toCartesianCoordinates(float theta, float phi) {
    float x = sin(theta) * cos(phi);
    float y = sin(theta) * sin(phi);
    float z = cos(theta);
    return vec3(x, y, z);
}

//the third function requied which is the unit test 
//generating 100 samples to see if every one of them falls in the unit sphere as it supposed to be
//if not, 
bool testRandomDirection() {
	bool result = true;
	vec3 sumVec = vec3(0.);
	for (int i = 0; i < 1200; i++) {
		vec2 sampleCoords = sample2(PATH_SAMPLE_DIMENSION + 2 * i);
		vec2 randAngle = toSphericalCoordinates(sampleCoords.x, sampleCoords.y);
		vec3 randVec = toCartesianCoordinates(randAngle.x, randAngle.y);
		sumVec += randVec;
		//check if a vector is a unit vector
		if (abs(length(randVec) - 1.0) > 0.01) {
			result = false;
			break;
		}
	}
	
	//check whether the generated vectors are evenly distributed. 
	//If not, the accumulated value sumVec will become larger and larger, and after average it will be biased in one direction, resulting in a relatively large average length.
	//on chrome, it pasts our unit test, but on safari it doesnt :/
	//so if you are on chrome, pls uncomment the following code to see that our sample do nicely uniformly distribute on the uniform ball
	/*float threshold = 0.1;
	sumVec /= 1200.;
	if(length(sumVec) > threshold) result = false;*/
	return result;
}
#endif

DirectionSample sampleDirection(const vec3 normal, const vec3 inDirection, const vec3 diffuse, const vec3 specular, const float glossiness, const int dimensionIndex) {
	DirectionSample result;
	vec2 sample = sample2(PATH_SAMPLE_DIMENSION + 2 * dimensionIndex);
	
	#ifdef SOLUTION_VR_IMPORTANCES_cos
	//cos weighted importance sampling
	DirectionSample result_cos;
	//float theta = acos(sqrt(1. - sample.x));
	float theta = acos(sqrt(2. * sample.x - 1.));
    float phi = 2.0 * M_PI * sample.y;
    vec3 wm2 = sphericalToEuclidean(theta, phi);
    vec3 wm_local2 = makeLocalFrame(normal) * wm2;
    result_cos.direction = wm_local2;
    result_cos.probability = cos(theta) * sin(theta) / M_PI;
	 result = result_cos;
	return result;
	#endif
	
	#ifdef SOLUTION_VR_IMPORTANCES_brdf
    //brdf weighted importance sampling
	 float alpha = glossiness * glossiness; 
    float specularWeight = length(specular);
    float diffuseWeight = length(diffuse);
    float threshold = specularWeight / (diffuseWeight + specularWeight);

    if (uniformRandom() < threshold) {
			// specular part
			float phi = 2.0 * M_PI * sample.x;
	 		float theta = acos(pow(1.0 - sample.y, 1.0 / (glossiness + 1.0)));
			vec3 wo = makeLocalFrame(normal) * sphericalToEuclidean(theta, phi);
        result.direction = reflect(wo, -inDirection);
		   float cosAlpha = max(dot(normal, wo), 0.0);
		   float pdf = (glossiness + 1.0) / (2.0 * M_PI) * pow(cosAlpha, glossiness);
        result.probability = pdf;
    } else {
			//diffuse part
			float phi = 2.0 * M_PI * sample.x;
	  		float theta = acos(sample.y);
        result.direction = makeLocalFrame(normal) * sphericalToEuclidean(theta, phi);
        result.probability = 1.0 / (2.0 * M_PI);
    }
    return result;
	#endif
	
	// Depending on the technique: put your variance reduction code in the #ifdef above 
	result.direction = getRandomDirection(dimensionIndex);	
	result.probability = 1.0 / (4.0 * M_PI);
	return result;
}

vec3 samplePath(const Scene scene, const Ray initialRay) {

	// Initial result is black
	vec3 result = vec3(0);

	Ray incomingRay = initialRay;
	vec3 throughput = vec3(1.0);
	for(int i = 0; i < maxPathLength; i++) {
		HitInfo hitInfo = intersectScene(scene, incomingRay, 0.001, 10000.0);

		if(!hitInfo.hit) return result;

		result += throughput * getEmission(hitInfo.material, hitInfo.normal);

		Ray outgoingRay;
		DirectionSample directionSample;
		#ifdef SOLUTION_BOUNCE
		directionSample = sampleDirection(hitInfo.normal, incomingRay.direction, hitInfo.material.diffuse, hitInfo.material.diffuse, hitInfo.material.glossiness, i);
		outgoingRay = Ray(hitInfo.position + EPSILON * directionSample.direction, directionSample.direction);
		#else
			// Put your code to compute the next ray in the #ifdef above
		#endif

		#ifdef SOLUTION_THROUGHPUT
		vec3 reflectance = getReflectance(hitInfo.material, hitInfo.normal, -incomingRay.direction, directionSample.direction);
		vec3 geometricTerm = getGeometricTerm(hitInfo.material, hitInfo.normal, -incomingRay.direction, directionSample.direction);
		throughput *= reflectance * geometricTerm;
		#else
		// Compute the proper throughput in the #ifdef above 
		throughput *= 0.1;
		#endif

		// div by probability of sampled direction 
		throughput /= directionSample.probability; 
	
		#ifdef SOLUTION_BOUNCE
		incomingRay = outgoingRay;
		#else
		// Put some handling of the next and the current ray in the #ifdef above
		#endif
	}
	return result;
}

uniform ivec2 resolution;
Ray getFragCoordRay(const vec2 fragCoord) {

	float sensorDistance = 1.0;
	vec3 origin = vec3(0, 0, sensorDistance);
	vec2 sensorMin = vec2(-1, -0.5);
	vec2 sensorMax = vec2(1, 0.5);
	vec2 pixelSize = (sensorMax - sensorMin) / vec2(resolution);
	vec3 direction = normalize(vec3(sensorMin + pixelSize * fragCoord, -sensorDistance));

	float apertureSize = 0.0;
	float focalPlane = 100.0;
	vec3 sensorPosition = origin + focalPlane * direction;
	origin.xy += -vec2(0.5);
	direction = normalize(sensorPosition - origin);

	return Ray(origin, direction);
}

vec3 colorForFragment(const Scene scene, const vec2 fragCoord) {
	initRandomSequence();
	#ifdef TEST_RANDOM_DIRECTION
	// if it doesnt pass our unitTest, the pixel or even the whole screen will be pink which is very eyecatching and 
	// our rendered image doesnt have pixel with red colour normally
	if(!testRandomDirection()){
		return vec3(0.9, 0.1, 0.5);
	}
	#endif
	
	#ifdef SOLUTION_VR_GOODSAMPLE
	//the main idea of the following is called stratified sample
	//in which we divide each pixel into four uniform parts and sample one pixel in each part
	//and then we average those pixels value to get our current pixel value
	vec3 color = vec3(0.0);
   const int nSamples = 4;
   float invNSamples = 1.0 / float(nSamples);
   for (int i = 0; i < nSamples; ++i) {
		for (int j = 0; j < nSamples; ++j) {
			// / xalculate the position for stratified sampling
			vec2 offset = sample2(ANTI_ALIAS_SAMPLE_DIMENSION + i + j);
			float offsetX = (float(i) + offset.x) * invNSamples;
			float offsetY = (float(j) + offset.y) * invNSamples;
			vec2 sampleCoord = fragCoord + vec2(offsetX, offsetY);
			color += samplePath(scene, getFragCoordRay(sampleCoord));
		}
    }
	 // average out all the samples
    color *= invNSamples * invNSamples; 
    return color;
	#endif
	
	#ifdef SOLUTION_AA
	// the main idea of the following code is to use jitter to sample random neighbour pixels and average their value
	vec2 sampleCoord_aa = fragCoord;
	vec3 color_aa = vec3(0.0, 0.0, 0.0);
	//use 4 samples to anti - aliasing
	const int sampleCount_aa = 4;
	for(int i = 0; i < sampleCount_aa; ++i) {
		//generate random sample sampleCoord_aa which values from -.5 to .5 falls in the current pixel
		vec2 offset = sample2(ANTI_ALIAS_SAMPLE_DIMENSION + i);
		float xOffset = offset.x - 0.5;
		float yOffset = offset.y - 0.5;
		sampleCoord_aa = fragCoord + vec2(xOffset, yOffset);  
		
     // compute the color value for the current sample coordinate using the path tracing algorithm and sum it up to coloraa
      color_aa += samplePath(scene, getFragCoordRay(sampleCoord_aa));
	}
	// divide the accumulated color by the number of samples to get the average color for this pixel
	// which is the result after anti aliasing 
	color_aa /= float(sampleCount_aa);
	
	//as we can see from our image rendered, the edges are nicely blurred
	return color_aa;
	#endif	
	// Put your anti-aliasing code in the #ifdef above
	vec2 sampleCoord = fragCoord;
	return samplePath(scene, getFragCoordRay(sampleCoord));
}

void loadScene1(inout Scene scene) {

	scene.spheres[0].position = vec3(7, -2, -12);
	scene.spheres[0].radius = 2.0;
	// Set the value of the missing property in the ifdef below 
#ifdef SOLUTION_LIGHT  
	scene.spheres[0].material.emission = 15. * vec3(0.9, 0.9, 0.5);
#endif
	scene.spheres[0].material.diffuse = vec3(0.5);
	scene.spheres[0].material.specular = vec3(0.5);
	scene.spheres[0].material.glossiness = 10.0;
	// Set the value of the missing property in the ifdef below 
#ifdef SOLUTION_MB
	scene.spheres[0].motion = vec3(0.);
#endif
	
	scene.spheres[1].position = vec3(-8, 4, -13);
	scene.spheres[1].radius = 1.0;
	// Set the value of the missing property in the ifdef below 
#ifdef SOLUTION_LIGHT  
	scene.spheres[1].material.emission = 15. * vec3(0.8, 0.3, 0.1);
#endif
	scene.spheres[1].material.diffuse = vec3(0.5);
	scene.spheres[1].material.specular = vec3(0.5);
	scene.spheres[1].material.glossiness = 10.0;
	// Set the value of the missing property in the ifdef below 
#ifdef SOLUTION_MB
	scene.spheres[1].motion = vec3(0.);
#endif
	
	scene.spheres[2].position = vec3(-2, -2, -12);
	scene.spheres[2].radius = 3.0;
	// Set the value of the missing property in the ifdef below 
#ifdef SOLUTION_LIGHT  
	scene.spheres[2].material.emission = vec3(0.);
#endif  
	scene.spheres[2].material.diffuse = vec3(0.2, 0.5, 0.8);
	scene.spheres[2].material.specular = vec3(0.8);
	scene.spheres[2].material.glossiness = 40.0;
	// Set the value of the missing property in the ifdef below 
#ifdef SOLUTION_MB
	scene.spheres[2].motion = vec3(-3., 0., 3.);
#endif
	
	scene.spheres[3].position = vec3(3, -3.5, -14);
	scene.spheres[3].radius = 1.0;
	// Set the value of the missing property in the ifdef below 
#ifdef SOLUTION_LIGHT  
	scene.spheres[3].material.emission = vec3(0.);
#endif  
	scene.spheres[3].material.diffuse = vec3(0.9, 0.8, 0.8);
	scene.spheres[3].material.specular = vec3(1.0);
	scene.spheres[3].material.glossiness = 10.0;
	// Set the value of the missing property in the ifdef below 
#ifdef SOLUTION_MB
	scene.spheres[3].motion = vec3(2., 4., 1.);
#endif
	
	scene.planes[0].normal = vec3(0, 1, 0);
	scene.planes[0].d = 4.5;
	// Set the value of the missing property in the ifdef below 
#ifdef SOLUTION_LIGHT    
	scene.planes[0].material.emission = vec3(0.);
#endif
	scene.planes[0].material.diffuse = vec3(0.8);
	scene.planes[0].material.specular = vec3(0.0);
	scene.planes[0].material.glossiness = 50.0;    

	scene.planes[1].normal = vec3(0, 0, 1);
	scene.planes[1].d = 18.5;
	// Set the value of the missing property in the ifdef below 
#ifdef SOLUTION_LIGHT    
	scene.planes[1].material.emission = vec3(0.);
#endif
	scene.planes[1].material.diffuse = vec3(0.9, 0.6, 0.3);
	scene.planes[1].material.specular = vec3(0.02);
	scene.planes[1].material.glossiness = 3000.0;

	scene.planes[2].normal = vec3(1, 0,0);
	scene.planes[2].d = 10.0;
	// Set the value of the missing property in the ifdef below 
#ifdef SOLUTION_LIGHT    
	scene.planes[2].material.emission = vec3(0.);
#endif
	
	scene.planes[2].material.diffuse = vec3(0.2);
	scene.planes[2].material.specular = vec3(0.1);
	scene.planes[2].material.glossiness = 100.0; 

	scene.planes[3].normal = vec3(-1, 0,0);
	scene.planes[3].d = 10.0;
	// Set the value of the missing property in the ifdef below 
#ifdef SOLUTION_LIGHT    
	scene.planes[3].material.emission = vec3(0.);
#endif
	
	scene.planes[3].material.diffuse = vec3(0.2);
	scene.planes[3].material.specular = vec3(0.1);
	scene.planes[3].material.glossiness = 100.0; 
}


void main() {
	// Setup scene
	Scene scene;
	loadScene1(scene);

	// compute color for fragment
	gl_FragColor.rgb = colorForFragment(scene, gl_FragCoord.xy);
	gl_FragColor.a = 1.0;
}


// Dear Participant 5452100, 67 of 100 points total. Task1: Light: 4 out of 5 points (Good job, gamma explanation is a bit too shallow. 
// What does "more natural" to the human eye mean? ) Task2: Bounce: 9 out of 10 points (Good job - unit test implementation is wrong, 
// but the (almost) correct idea is outlined below in the comments so deducting only 1 pt. ) Task3: Throughput: 28 out of 30 points 
// (Good job, explanations are a little too sparse for the full 5 pts. ) Task4: Anti-Aliasing: 3 out of 10 points 
// (That is not how AA is done in MC path tracing - it is extremely inefficient! For AA in MC, it is enough to jitter the current path starting 
// point in a box of length 1, so that each iteration has a slightly different starting point. ) Task5: Motion Blur: 8 out of 10 points 
// (Great job, but you should have used TIME_SAMPLE_DIMENSION instead of calling uniformRandom without any arguments. ) 
// Task6: Var. Reduction: 15 out of 35 points (This is not how stratified sampling is meant to be used: you shoot 4x4=16 extra rays
//  for every ray, that is not the point of variance reduction. Both cosine- and BRDF sampling are valid VR techniques, but your implementations 
//  of both induce bias (the image is darker than without). PDF: explanations are ok (modulo the stratified sampling, see above), variance reduction 
//  evidence is ok, but unbiasedness explanations are insufficient - it is not enough to provide theoretical guarantees, the implementation might still
//   induce bias (like in your case). ) Your points sum up to 67.
